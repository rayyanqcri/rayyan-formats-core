require 'tempfile'

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
        @@extensions_str = @@plugins.map{|plugin| plugin.extension}.join(", ")
        @@logger = nil
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
      def logger=(value); @@logger = value end
      def logger(message); @@logger.debug(message) if @@logger end
      def extensions_str; @@extensions_str end

      def import(source, &block)
        filename = source.name
        original_ext = File.extname(filename).delete('.')
        plugin = match_plugin(original_ext)
        raise "Unsupported file format: #{original_ext}, please use one of: #{extensions_str}" unless plugin

        # check file size, otherwise the worker process will crash for huge files
        file = source.attachment
        raise "The file is too big to process, should be less than #{max_file_size} bytes in size" if file.size > max_file_size

        plugin.do_import(file.read, filename, &block)
      ensure
        file.close if file
      end

      protected

      # plugin DSL block setters/getters
      def do_import(*arguments, &block)
        if arguments.length == 0
          @plugin_import_block = block
        else
          logger "Inside #{self.title} parser for file: #{arguments[1] rescue ''}"
          @plugin_import_block.call(*arguments, &block)
        end
      end

      def detect(*arguments, &block)
        if arguments.length == 0
          @plugin_detect_block = block
        else
          logger "Detecting #{self.title}"
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

      private

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
          raise "Unsupported file contents, please use a proper way to export your files into one of these formats: #{extensions_str}"
        end
      end

      def match_plugin(ext)
        plugin = plugins.find{|plugin| plugin.extension == ext.downcase}
        return nil if plugin.nil?
        # force core extensions to txt to pass by encoding and plugin detection filters
        return plugin.is_core? ? RayyanFormats::Plugins::PlainText : plugin
      end

    end # class methods
  end # class
end # module
