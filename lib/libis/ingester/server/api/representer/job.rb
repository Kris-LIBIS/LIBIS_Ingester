require_relative 'base'

module Libis::Ingester::API::Representer
  class JobRepresenter < Grape::Roar::Decorator
    include Base

    type :jobs

    attributes do
      property :name, type: String, desc: 'job name'
      property :description, type: String, desc: 'job description'
    end

  end
end