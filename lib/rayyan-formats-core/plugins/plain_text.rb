module RayyanFormats
  module Plugins
    class PlainText < RayyanFormats::Base

      title 'Plain Text'
      extension 'txt'
      description 'Supports plain text files in one of the above mentioned formats.'

      do_import do |body, filename, &block|
        format, lines = self.detect_import_format(body)
        format.do_import(lines.join("\n"), filename, &block)
      end
    end
  end
end
