module RayyanFormats
  module Plugins
    class PlainText < Base

      title 'Plain Text'
      extension 'txt'
      description 'Supports plain text files in one of the above mentioned formats.'

      parse do |body, filename, &block|
        format, lines = self.detect_import_format(body)
        format.parse(lines.join("\n"), filename, &block)
      end
    end
  end
end
