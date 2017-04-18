require 'uri'
require 'uri/query_params'

module Libis
  module Ingester
    module API
      module Representer
        module Pagination

          def for_pagination
            for_collection.tap do |representer|
              representer.class_eval do
                def page_url(opts, page = nil, offset = nil)
                  url = opts[:this_url]
                  return url if page.nil? && offset.nil?
                  return url unless opts && opts[:pagination] && opts[:pagination][:total] > 1
                  page = (page || opts[:pagination][:page] rescue 1) + offset.to_i
                  uri = URI::parse(url)
                  uri.query_params['page'] = page
                  uri.to_s
                end

                def next_url(opts)
                  page_url(opts, nil, 1) if (opts[:pagination][:page] < opts[:pagination][:total] rescue false)
                end

                def prev_url(opts)
                  page_url(opts, nil, -1) if (opts[:pagination][:page] > 1 rescue false)
                end

                def first_url(opts)
                  page_url(opts, 1) if (opts[:pagination][:total] > 1 rescue false)
                end

                def last_url(opts)
                  page_url(opts, (opts[:pagination][:total] rescue 1)) if (opts[:pagination][:total] > 1 rescue false)
                end

                link(:self) {|opts| page_url(opts)}
                link(:next) {|opts| next_url opts}
                link(:prev) {|opts| prev_url opts}
                link(:first) {|opts| first_url opts}
                link(:last) {|opts| last_url opts}

                meta do
                  property :total_pages, as: :per_page
                  property :total_count, as: :item_count
                  property :current_page
                  property :total_pages
                  property :next_page
                  property :prev_page
                end
              end
            end
          end
        end
      end
    end
  end
end