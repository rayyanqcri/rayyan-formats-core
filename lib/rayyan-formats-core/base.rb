module RayyanFormats
  class Base
    MAX_SKIP_LINES = 10

    # format instance easy access delegators (optional)
    # def method_missing(method_sym, *arguments, &block)
    #   if [:title, :extension, :description, :detect, :parse, :is_core?].include? method_sym
    #     self.class.send(method_sym, *arguments, &block)
    #   else
    #     super(method_sym, *arguments, &block)
    #   end
    # end

    class << self  
      # format DSL setters/getters
      def title(*arguments, &block)
        @format_title = arguments.first if arguments.length > 0
        @format_title
      end

      def extension(*arguments, &block)
        @format_extension = arguments.first if arguments.length > 0
        @format_extension
      end

      def description(*arguments, &block)
        @format_description = arguments.first if arguments.length > 0
        @format_description
      end

      def detect(*arguments, &block)
        if arguments.length == 0
          @format_detect_block = block
        else
          Rails.logger.debug "Detecting #{self.title}"
          @format_detect_block.call(*arguments, &block)
        end
      end

      def is_core?
        !!@format_detect_block
      end

      def do_import(*arguments, &block)
        if arguments.length == 0
          @format_import_block = block
        else
          # Rails.logger.debug "Inside #{self.title} parser for file: #{arguments[1] rescue ''}"
          @format_import_block.call(*arguments, &block)
        end
      end

      def formats=(list)
        @@text_format = RayyanFormats::Plugins::PlainText
        @@csv_format = RayyanFormats::Plugins::CSV
        @@formats = list.reject{|klass|
          [RayyanFormats::Plugins::PlainText, RayyanFormats::Plugins::CSV].include? klass
        } << @@text_format << @@csv_format
        @@extensions_str = @@formats.map{|f| f.extension}.join(", ")
        @@formats
      end

      def formats
        @@formats
      end

      def max_file_size=(value)
        @@max_file_size = value
      end

      def max_file_size
        @@max_file_size rescue 10_485_760 # 10 megabytes
      end

      def extensions_str
        @@extensions_str
      end

      def text_format
        @@text_format
      end

      def match_format(ext)
        format = @@formats.find{|f| f.extension == ext.downcase}
        raise "Unsupported file format detected: #{ext}" if format.nil?
        # force core extensions to txt to pass by encoding and format detection filters
        return format.is_core? ? text_format : format
      end

      def import(source, &block)
        filename = source.name
        original_ext = File.extname(filename).delete('.')
        format = match_format(original_ext)
        raise "Unsupported file format: #{original_ext}, please use one of: #{extensions_str}" unless format

        # check file size, otherwise the worker process will crash for huge files
        file = source.attachment
        raise "The file is too big to process, should be less than #{max_file_size} bytes in size" if file.size > max_file_size

        format.do_import(file.read, filename, &block)
      ensure
        file.close if file
      end

      def detect_import_format(fileContent)
        utf8 = detect_encoding_convert(fileContent)
        lines = utf8.split(/\n\r|\r\n|\n|\r/)
        raise 'Empty file' if lines.length == 0
        detect_import_format_recursive(lines, 0)
      end

      def detect_import_format_recursive(lines, skipped)
        # return format based on contect or raise error if unsupported
        first_line = lines[skipped].lstrip
        format = formats.find{|f|
          f != @@csv_format && f.is_core? && f.detect(first_line, lines)
        }
        if format
          return format, lines[skipped..-1]
        elsif skipped < MAX_SKIP_LINES && skipped + 1 < lines.length
          return detect_import_format_recursive(lines, skipped + 1)
        elsif @@csv_format.detect(lines.first, lines) # nothing detected, csv last resort
          return @@csv_format, lines
        else
          raise "Unsupported file contents, please use a proper way to export your files into one of these formats: #{extensions_str}"
        end
      end

      def detect_encoding_convert(body)
        # write body in a file
        infile = Tempfile.new ''
        infile.binmode
        infile.write(body)
        infile.close
        # create empty outfile
        outfile = Tempfile.new ''
        outfile.close

        # call thrift detect
        encoding = nil
        lthrift {|client|
          encoding = client.detect_encoding_convert infile.path, outfile.path
        }
        body = File.read(outfile.path) if encoding != 'UTF-8'

        # Remove BOM Characters
        body.force_encoding("UTF-8").sub("\xEF\xBB\xBF", "")
      end

      def get_notes(val)
        return nil if val.nil?
        val = val.join("\n") if val.respond_to?(:join)
        val
      end

    end # class methods
  end # class
end # module
