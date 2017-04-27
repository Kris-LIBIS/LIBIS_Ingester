Dir[File.expand_path('../../representer/*.rb', __FILE__)].each do |f|
  # noinspection RubyResolve
  require f
end

module Libis::Ingester::API::RepresentHelper
  extend Grape::API::Helpers

  def present_item(representer:, item:, options: {}, default_fields: {})
    opts = item_hash(item, options)
    if params.has_key? :fields || !default_fields.empty?
      opts.merge!(fields_opts(params[:fields], default_fields))
    end
    representer.prepare(item).to_hash(opts)
  end

  def present_collection(representer:, collection:, with_pagination: false, options: {}, default_fields: {})
    opts = with_pagination ? pagination_hash(collection, options) : option_hash(options)
    if params.has_key? :fields || !default_fields.empty?
      opts.merge!(fields_opts(params[:fields], default_fields))
    end
    # .send(with_pagination ? :for_pagination : :for_collection)
    representer
        .for_pagination
        .prepare(collection)
        .to_hash(opts)
  end

  def parse_item(representer:, item: )
    representer.prepare(item).from_hash(declared(params))
    item
  end

  def item_hash(item, default = {})
    option_hash(default).tap do |h|
      h[:user_options].merge!(links: item_links(item, "#{base_url}#{namespace}"))
    end
  end

  def pagination_hash(collection, default = {})
    option_hash(default).tap do |h|
      h[:user_options].merge!(
          pagination: {
              page: collection.current_page,
              total: collection.total_pages,
              per: declared(params).per_page
          }
      )
      h.merge!(
        meta: {
            current_page: collection.current_page,
            total_pages: collection.total_pages,
            total_count: collection.total_count,
            per_page: collection.limit_value
        }
      )
      h[:meta][:next_page] = collection.next_page if collection.next_page
      h[:meta][:prev_page] = collection.prev_page if collection.prev_page
    end
  end

  def option_hash(default = {})
    default.dup.tap do |h|
      (h[:user_options] ||= {})[:base_url] = base_url
      # noinspection RubyResolve
      (h[:user_options] ||= {})[:this_url] = @request.url
    end
  end

  def item_links(item, base_url)
    {
        self: "#{base_url}/#{item.id}",
        all: "#{base_url}",
    }
  end

end
