require 'csv'

module RayyanFormats
  module Plugins
    class CSV < RayyanFormats::Base

      title 'CSV'
      extension 'csv'
      description 'Supports header column names: ' + %w(
        key
        title
        year
        month
        day
        journal
        issn
        volume
        issue
        pages
        authors
        url
        language
        publisher
        location
        abstract
        notes
        pubmed_id
        pmc_id
      ).join(', ') + ' in any order'

      MAX_CSV_ROWS_DETECT = 5

      detect do |first_line, lines|
        begin
          # check if first line has "title" header
          col_regex = /\s*,\s*/
          header = first_line.split(col_regex).map(&:downcase)
          if !header.include?('title')
            logger.debug 'CSV header has no title field'
            raise 'no title'
          end
          next true
        rescue
          next false
        end
      end

      do_import do |body, filename, &block|
        articles = ::CSV.parse(body, {:headers => true, :return_headers => false, :header_converters => :symbol})
        total = articles.length
        articles.each do |article|
          target = Target.new
          target.publication_types = ["Journal Article"]
          target.sid = article[:key]
          target.title = article[:title]
          target.date_array = [article[:year], article[:month] || 1, article[:day] || 1]
          target.journal_title = article[:journal]
          target.journal_issn = article[:issn]
          target.jvolume = article[:volume].to_i rescue 0
          target.jissue = (article[:issue] || article[:number]).to_i rescue 0
          target.pagination = article[:pages]
          target.authors = article[:authors].split(/\s*;\s*|\band\b/) if article[:authors]
          target.url = article[:url]
          target.language = article[:language]
          target.publisher_name = article[:publisher]
          target.publisher_location = article[:location]
          target.abstracts = [article[:abstract]].compact
          target.notes = try_join_arr(article[:notes])
          target.article_ids = article_ids_headers.map do |idtype|
            { idtype: idtype, value: article[idtype] } if article[idtype]
          end.compact

          block.call(target, total)
        end
      end

      do_export do |target, options|
        header = options[:include_header] ? emit_header : ''
        if target.nil?
          body = ''
        else
          body_array = [
            target.sid,
            target.title,
            target.date_array ? target.date_array[0] : nil,
            target.date_array ? target.date_array[1] : nil,
            target.date_array ? target.date_array[2] : nil,
            target.journal_title,
            target.journal_issn,
            target.jvolume && target.jvolume > 0 ? target.jvolume : nil,
            target.jissue && target.jissue > 0 ? target.jissue : nil,
            target.pagination,
            target.authors&.join(' and '),
            target.url,
            target.language,
            target.publisher_name,
            target.publisher_location,
            get_abstracts(target, options){|abstracts| abstracts.join("\n").strip},
            target.notes
          ]

          # Generate article ids from target
          article_ids = article_ids_headers.map do |idtype|
            id_obj = target.article_ids&.detect do |target_id_obj|
              target_id_obj[:idtype] == idtype
            end
            id_obj&.dig(:value)
          end

          # Append article ids to body
          body = (body_array + article_ids).to_csv
        end

        header + body
      end

      class << self
        private

        def article_ids_headers
          %i[pubmed_id pmc_id]
        end

        def emit_header
          ([
            "key",
            "title",
            "year",
            "month",
            "day",
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
            "notes",
          ] + article_ids_headers.map(&:to_s)
          ).to_csv
        end
      end

    end # class
  end # module
end # module
