require 'uri'
require 'uri/query_params'

module Libis::Ingester::API::Representer
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

          # meta do
          #   property :current_page, exec_context: :decorator
          #   property :total_pages, exec_context: :decorator
          #   property :next_page, exec_context: :decorator
          #   property :prev_page, exec_context: :decorator
          #   property :total_count, exec_context: :decorator
          #   property :limit_value, as: :per_page, exec_context: :decorator
          # end
          #
          # def current_page
          #   respresented.respond_to?(:current_page) ? represented.current_page : nil
          # end

        end
      end
    end
  end
end