require 'roar/coercion'
require 'active_support/concern'
require_relative 'resource_collection'
require_relative 'pagination'


Object.module_eval do
  def self.const_unset(const)
    self.instance_eval { remove_const(const) }
  end
end
Roar::JSON::JSONAPI::Options::Include.const_unset(:DEFAULT_INTERNAL_INCLUDES)
Roar::JSON::JSONAPI::Options::Include::DEFAULT_INTERNAL_INCLUDES = [:attributes, :relationships, :links].freeze

module Libis
  module Ingester
    module API
      module Representer
        module Base
          extend ActiveSupport::Concern

          def self_url(opts)
            self.class.self_url(opts)
          end

          module ClassMethods

            def self_url(opts)
              "#{opts[:base_url]}/#{self.type}"
            end

          end

          def self.included(klass)
            klass.class_eval do

              include Roar::JSON
              include Roar::Coercion
              include Representable::Hash
              include Representable::Hash::AllowSymbols
              include Roar::JSON::JSONAPI::Mixin
              extend Pagination

              property :id, exec_context: :decorator, writable: false,
                       type: String, desc: 'Object\'s unique identifier'

              attributes do
                property :c_at, as: :created_at, writeable: false, type: DateTime, desc: 'Date when the object was created'
              end
              link(:self) do |opts|
                "#{self_url(opts)}/#{represented.id}"
              end

              link(:self, toplevel: true) do |opts|
                opts[:this_url]
              end

              def id
                represented.id.to_s
              end

              def id=(_value)
                # do nothing
              end

            end
          end

        end
      end
    end
  end
end
