require 'csv'

module RayyanFormats
  module Plugins
    class CSV < RayyanFormats::Base

      title 'CSV'
      extension 'csv'
      description 'Supports header column names: key,title,authors,journal,issn,volume,issue,pages,year,publisher,location,url,language,abstract in any order'

      MAX_CSV_ROWS_DETECT = 5

      detect do |first_line, lines|
        begin
          # if first few lines have same number of columns
          # and first line has "title" header
          col_regex = /\s*,\s*/
          header = first_line.split(col_regex).map(&:downcase)
          raise 'no title' if !header.include?('title')
          cols = header.length
          1.upto([MAX_CSV_ROWS_DETECT, lines.length - 1].min) { |l|
            raise 'mismatch' if lines[l].split(col_regex, -1).length < cols # -1: don't suppress empty fields
            # extra escaped commas could appear in non-header lines
          }
          next true
        rescue
          next false
        end
      end

      do_import do |body, filename, &block|
        articles = ::CSV.parse(body, {:headers => true, :return_headers => false, :header_converters => :symbol, :converters => :all})
        total = articles.length
        articles.each do |article|
          target = Target.new
          target.publication_types = ["Journal Article"]
          target.sid = article[:key].to_s
          target.title = article[:title].to_s
          target.date_array = [article[:year]]
          target.journal_title = article[:journal]
          target.journal_issn = article[:issn].to_s
          target.jvolume = article[:volume].to_i rescue 0
          target.jissue = (article[:issue] || article[:number]).to_i rescue 0
          target.pagination = article[:pages].to_s
          target.authors = article[:authors].split(/\s*;\s*|\s*and\s*/) if article[:authors]
          target.url = article[:url].to_s
          target.language = article[:language]
          target.publisher_name = article[:publisher]
          target.publisher_location = article[:location].to_s
          target.abstracts = [article[:abstract]].compact
          target.notes = try_join_arr(article[:notes])

          block.call(target, total)
        end
      end

      do_export do |target, options|
        header = options[:include_header] ? emit_header : ''
        body = target.nil? ? '' : [
          target.sid,
          target.title,
          target.date_array ? target.date_array.first : nil,
          target.journal_title,
          target.journal_issn,
          target.jvolume && target.jvolume > 0 ? target.jvolume : nil,
          target.jissue && target.jissue > 0 ? target.jissue : nil,
          target.pagination,
          target.authors.join(' and '),
          target.url,
          target.language,
          target.publisher_name,
          target.publisher_location,
          options[:include_abstracts] ? target.abstracts.join("\n").strip : nil,
          target.notes
        ].to_csv
        header + body
      end

      class << self
        private

        def emit_header
          [
            "key",
            "title",
            "year",
            "journal",
            "issn",
            "volume",
            "issue",
            "pages",
            "authors",
            "url",
            "language",
            "publisher",
            "location",
            "abstract",
            "notes"
          ].to_csv
        end
      end

    end # class
  end # module
end # module
