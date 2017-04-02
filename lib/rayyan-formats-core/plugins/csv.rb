require 'csv'

module RayyanFormats
  module Plugins
    class CSV < Base

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

      parse do |body, filename, &block|
        articles = ::CSV.parse(body, {:headers => true, :return_headers => false, :header_converters => :symbol, :converters => :all})
        total = articles.length
        articles.each do |article|
          mArticle = Article.new
          mArticle.sid = article[:key].to_s
          mArticle.title = article[:title].to_s
          mArticle.jcreated_at = ScraperBase.to_date article[:year]
          mArticle.jvolume = article[:volume].to_i rescue 0
          mArticle.pagination = article[:pages].to_s

          mArticle.insert_ordered_authors(article[:authors].split(/\s*;\s*|\s*and\s*/)) if article[:authors]

          mArticle.abstracts.build content: article[:abstract] if article[:abstract]

          mArticle.publication_types << PublicationType.where(name: "Journal Article").first_or_initialize

          mArticle.jissue = (article[:issue] || article[:number]).to_i rescue 0
          mArticle.url = article[:url].to_s

          mArticle.publisher = Publisher.where(name: article[:publisher]).first_or_initialize {|p|
            p.location = article[:location].to_s
          } unless article[:publisher].blank?

          journal = article[:journal]
          mArticle.journal = Journal.where(title: journal).first_or_create {|j|
            j.issn = article[:issn].to_s
          } unless journal.blank?

          mArticle.language = article[:language]
          mArticle.notes = article[:notes]

          block.call(mArticle, total)
        end
      end

    end # class
  end # module
end # module
