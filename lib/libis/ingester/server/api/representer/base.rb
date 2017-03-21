require_relative 'base'
require 'active_support/concern'

module Libis::Ingester::API::Representer
  module ItemList
    extend ActiveSupport::Concern

    module ClassMethods

      def page_url(opts, page = nil, offset = nil)
        return nil unless opts
        page ||= opts[:pagination][:page] rescue 1
        offset ||= 0
        url = ["#{opts[:base_url]}/#{self.type}"]
        url << %W(per_page=#{opts[:pagination][:per] rescue 10} page=#{page + offset}).join('&') if opts[:pagination]
        url.join('?')
      end

      def self_url(opts)
        page_url(opts)
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
    end

    def self.included(klass)
      klass.class_eval do
        include Base

        link(:self) { |opts| "#{opts[:base_url]}/#{self.class.type}/#{represented.id}" }
        # link(:all) { |opts| "#{opts[:base_url]}/#{self.class.type}" }

        link(:self, toplevel: true) { |opts| klass.self_url opts }
        link(:next, toplevel: true) { |opts| klass.next_url opts}
        link(:prev, toplevel: true) { |opts| klass.prev_url opts}
        link(:first, toplevel: true) { |opts| klass.first_url opts}
        link(:last, toplevel: true) { |opts| klass.last_url opts}

        meta toplevel: true do
          property :limit_value, as: :per_page
          property :total_count
          property :current_page
          property :total_pages
          property :next_page
          property :prev_page
        end
      end


    end

  end
end
