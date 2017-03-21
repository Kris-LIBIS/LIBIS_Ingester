require_relative 'item'

module Libis::Ingester::API::Representer
  class RunRepresenter < ItemRepresenter

    type :runs

    attributes do
      property :name, writable: false, type: String, desc: 'run name'
      property :start_date, type: DateTime, desc: 'start date'
      property :log_to_file, type: Boolean, desc: 'write log to file'
      property :log_level, type: String, desc: 'log level'
      property :run_name, type: String, desc: 'identifying run name'
    end

    link :job do

    end

  end
end