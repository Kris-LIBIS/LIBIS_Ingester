module Libis
  module Ingester
    module API
      module Representer
        module Pagination

          def for_pagination
            for_collection.tap do |representer|
              representer.class_eval do
                def page_url(opts, page = nil, offset = nil)
                  return nil unless opts
                  page ||= opts[:pagination][:page] rescue 1
                  offset ||= 0
                  url = [self_url(opts)]
                  url << %W(per_page=#{opts[:pagination][:per] rescue 10} page=#{page + offset}).join('&') if opts[:pagination]
                  url.join('?')
                end

                def next_url(opts)
                  page_url(opts, nil, 1) if (opts[:pagination][:page] < opts[:pagination][:total] rescue false)
                end

                def prev_url(opts)
                  page_url(opts, nil, -1) if (opts[:pagination][:page] > 1 rescue false)
                end

                def first_url(opts)
                  page_url(opts, 1)
                end

                def last_url(opts)
                  page_url(opts, (opts[:pagination][:total] rescue 1))
                end

                link(:self) { |opts| page_url(opts) }
                link(:next) { |opts| self.class.next_url opts }
                link(:prev) { |opts| self.class.prev_url opts }
                link(:first) { |opts| self.class.first_url opts }
                link(:last) { |opts| self.class.last_url opts }
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