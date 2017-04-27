require 'libis/ingester/item'
require 'libis/ingester/file_item'
require 'libis/ingester/dir_item'
require 'libis/ingester/dir_collection'
require 'libis/ingester/dir_division'
require 'libis/ingester/division'
require 'libis/ingester/representation'
require 'libis/ingester/intellectual_entity'
require 'libis/ingester/collection'

module Libis::Ingester::API
  class Items < Grape::API
    include Grape::Kaminari

    REPRESENTER = Representer::Item
    DB_CLASS = Libis::Ingester::Item

    namespace :items do

      helpers ParamHelper
      helpers StatusHelper
      helpers RepresentHelper
      helpers ObjectHelper

      params do
        requires :item_id, type: String, desc: 'item ID', allow_blank: false, item_id: true
      end
      route_param :item_id do

        desc 'get item information' do
          success REPRESENTER
        end
        params do
          use :item_fields
        end
        get do
          present_item(representer: REPRESENTER, item: current_item)
        end

        desc 'update item information' do
          success REPRESENTER
        end
        params do
          requires :data, type: REPRESENTER, desc: 'item info'
        end
        put do
          guard do
            _item = current_item
            parse_item(representer: REPRESENTER, item: _item)
            _item.save!
            present_item(representer: REPRESENTER, item: current_item)
          end
        end

        desc 'delete item'
        delete do
          guard do
            current_item.destroy
            api_success("item (#{declared(params)[:item_id]}) deleted")
          end
        end

        desc 'get child items'
        paginate per_page: 10, max_per_page: 50
        params do
          use :item_fields
        end
        get 'items' do
          guard do
            present_collection(
                representer: REPRESENTER,
                collection: paginate(Kaminari.paginate_array(current_item.items)),
                with_pagination: true
            )
          end
        end

      end # route_param :item_id

    end # namespace :items

  end # Class

end # Module