require 'tempfile'
require_relative '../support/dummy_logger'

module RayyanFormats
  class Base
    MAX_SKIP_LINES = 10
    DEFAULT_MAX_FILE_SIZE = 10_485_760 # 10 megabytes

    class << self
      # class static initializer
      def initialize_class(plugins_list = [])
        @@max_file_size ||= DEFAULT_MAX_FILE_SIZE
        @@plugins = plugins_list.reject{|klass|
          [RayyanFormats::Plugins::PlainText, RayyanFormats::Plugins::CSV].include? klass
        } << RayyanFormats::Plugins::PlainText << RayyanFormats::Plugins::CSV
        @@import_extensions_str = @@plugins.map{|plugin|
          plugin.extension if plugin.can_import?
        }.compact.join(", ")
        @@export_extensions_str = @@plugins.map{|plugin|
          plugin.extension if plugin.can_export?
        }.compact.join(", ")
        @@logger ||= DummyLogger.new
        @@plugins
      end

      # plugin DSL simple setters/getters
      def title(*arguments, &block)
        @plugin_title = arguments.first if arguments.length > 0
        @plugin_title
      end

      def extension(*arguments, &block)
        @plugin_extension = arguments.first if arguments.length > 0
        @plugin_extension
      end

      def description(*arguments, &block)
        @plugin_description = arguments.first if arguments.length > 0
        @plugin_description
      end

      # public base methods
      def plugins=(list); initialize_class list end
      def plugins; @@plugins end
      def max_file_size=(value); @@max_file_size = value end
      def max_file_size; @@max_file_size end
      def logger=(value); @@logger = value || DummyLogger.new end
      def logger; @@logger end
      def import_extensions_str; @@import_extensions_str end
      def export_extensions_str; @@export_extensions_str end

      def import(source, &block)
        filename = source.name
        original_ext = File.extname(filename).delete('.')
        plugin = match_import_plugin(original_ext)
        raise "Unsupported file format: #{original_ext}, please use one of: #{import_extensions_str}" unless plugin

        # check file size, otherwise the worker process will crash for huge files
        file = source.attachment
        raise "The file is too big to process, should be less than #{max_file_size} bytes in size" if file.size > max_file_size

        plugin.do_import(file.read, filename, &block)
      ensure
        file.close if file
      end

      def get_export_plugin(ext)
        plugin = match_export_plugin(ext)
        raise "Unsupported file format: #{ext}, please use one of: #{export_extensions_str}" unless plugin
        plugin.new
      end

      protected

      # plugin DSL block setters/getters
      def do_import(*arguments, &block)
        if arguments.length == 0
          @plugin_import_block = block
        else
          logger.debug "Inside #{self.title} parser for file: #{arguments[1] rescue ''}"
          @plugin_import_block.call(*arguments, &block)
        end
      end

      def do_export(*arguments, &block)
        if arguments.length == 0
          @plugin_export_block = block
        else
          @plugin_export_block.call(*arguments, &block)
        end
      end

      def detect(*arguments, &block)
        if arguments.length == 0
          @plugin_detect_block = block
        else
          logger.debug "Detecting #{self.title}"
          @plugin_detect_block.call(*arguments, &block)
        end
      end

      # helper methods for plugins
      def try_join_arr(val)
        val.join("\n") rescue val
      end

      def detect_import_format(file_content)
        lines = file_content.split(/\n\r|\r\n|\n|\r/)
        raise 'Empty file' if lines.length == 0
        detect_import_format_recursive(lines, 0)
      end

      def is_core?
        !!@plugin_detect_block
      end

      def can_import?
        !!@plugin_import_block
      end

      def can_export?
        !!@plugin_export_block
      end

      def match_import_plugin(ext)
        plugin = match_plugin(ext){|plugin| plugin.can_import?}
        return nil if plugin.nil?
        # force core extensions to txt to pass by encoding and plugin detection filters
        return plugin.is_core? ? RayyanFormats::Plugins::PlainText : plugin
      end

      def match_export_plugin(ext)
        match_plugin(ext){|plugin| plugin.can_export?}
      end

      private

      def match_plugin(ext, &block)
        plugins.find{|plugin| plugin.extension == ext.downcase && block.call(plugin)}
      end

      def detect_import_format_recursive(lines, skipped)
        # return plugin based on contect or raise error if unsupported
        first_line = lines[skipped].lstrip
        csv_plugin = RayyanFormats::Plugins::CSV
        plugin = plugins.find{|plugin|
          plugin != csv_plugin && plugin.is_core? && plugin.send(:detect, first_line, lines)
        }
        if plugin
          return plugin, lines[skipped..-1]
        elsif skipped < MAX_SKIP_LINES && skipped + 1 < lines.length
          return detect_import_format_recursive(lines, skipped + 1)
        elsif csv_plugin.send(:detect, lines.first, lines) # nothing detected, csv last resort
          return csv_plugin, lines
        else
          raise "Unsupported file contents, please use a proper way to export your files into one of these formats: #{import_extensions_str}"
        end
      end

    end # class methods

    attr_accessor :exported_first_line, :base_id, :next_id

    def initialize
      @base_id = "id#{(rand*1e8).round}_"
      @next_id = 0
    end

    def get_unique_id
      @next_id += 1
      "#{@base_id}#{@next_id}"
    end

    def export(target, options = {})
      # delegate to the protected method
      options = options.merge(include_header: !!!exported_first_line, unique_id: get_unique_id)
      output = self.class.send(:do_export, target, options)
      @exported_first_line = true
      output
    end

  end # class
end # module
