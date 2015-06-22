# encoding: utf-8

require 'libis-services'

require 'libis/ingester/run'

require 'fileutils'

module LIBIS
  module Ingester

    class Submitter < ::Libis::Ingester::Task
      parameter login_name: nil,
                description: 'Deposit user login name.'
      parameter login_pass: nil,
                description: 'Deposit user password.'
      parameter login_inst: nil,
                description: 'Rosetta institution.'
      parameter flow_id: nil,
                description: 'Id of the material flow to use.'
      parameter producer_id: nil,
                description: 'Id of the producer to use.'

      def process(item)
        check_item_type ::Libis::Ingester::Run, item

        check_ingestable(item)

      end

      def check_ingestable(item)
        item.properties[:ingest_sub_dir] ?
            submit_item(item) :
            item.items.map { |i| check_ingestable(i) }
      end

      def submit_item(item)
        debug "Found ingestable item. Subdir: #{item.properties[:ingest_sub_dir]}", item
        rosetta = Libis::Services::Rosetta.new
        handle = rosetta.login(parameter(:login_name), parameter(:login_pass), parameter(:login_inst))
        raise Libis::WorkflowAbort, 'Could not log in into Rosetta.' if handle.nil?

        deposit_result = rosetta.deposit_service.submit(
            parameter(:flow_id),
            item.properties[:ingest_sub_dir],
            parameter(:producer_id)
        )
        raise Libis::WorkflowError, "SIP deposit failed: #{deposit_result[:error]}" if deposit_result[:error]

        item.properties[:ingest_sip] = deposit_result['sip_id']
        item.properties[:ingest_dip] = deposit_result['deposit_activity_id']
        item.save

        debug "Deposit ##{item.properties[:ingest_dip]} done. SIP: #{item.properties[:ingest_sip]}"
      end

    end
  end
end
