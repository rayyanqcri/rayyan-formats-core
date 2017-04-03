require 'csv'

module RayyanFormats
  module Plugins
    class CSV < RayyanFormats::Base

      title 'CSV'
      extension 'csv'
      description 'Supports header column names: key,title,authors,journal,issn,volume,issue,pages,year,publisher,location,url,language,abstract in any order'

      MAX_CSV_ROWS_DETECT = 5

      detect do |first_line, lines|
        # if first few lines have same number of columns
        # and first line has "title" header
        col_regex = /\s*,\s*/
        header = first_line.split(col_regex).map(&:downcase)
        next false if !header.include?('title')
        cols = header.length
        1.upto([MAX_CSV_ROWS_DETECT, lines.length - 1].min) { |l|
          next false if lines[l].split(col_regex, -1).length < cols # -1: don't suppress empty fields
          # extra escaped commas could appear in non-header lines
        }
        next true
      end

      do_import do |body, filename, &block|
        articles = ::CSV.parse(body, {:headers => true, :return_headers => false, :header_converters => :symbol, :converters => :all})
        total = articles.length
        articles.each do |article|
          target = Target.new
          target.sid = article[:key].to_s
          target.title = article[:title].to_s
          target.date_array = [article[:year]]
          target.jvolume = article[:volume].to_i rescue 0
          target.jissue = (article[:issue] || article[:number]).to_i rescue 0
          target.pagination = article[:pages].to_s
          target.authors = article[:authors].split(/\s*;\s*|\s*and\s*/) if article[:authors]
          target.url = article[:url].to_s
          target.language = article[:language]
          target.notes = try_join_arr(article[:notes])
          target.abstracts = [article[:abstract]].compact
          target.publication_types = ["Journal Article"]
          target.publisher_name = article[:publisher]
          target.publisher_location = article[:location].to_s
          target.journal_title = article[:journal]
          target.journal_issn = article[:issn].to_s

          block.call(target, total)
        end
      end

    end # class
  end # module
end # module
