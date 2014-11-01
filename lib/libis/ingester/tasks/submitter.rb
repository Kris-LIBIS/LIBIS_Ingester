# encoding: utf-8

require 'LIBIS_Workflow'
require 'LIBIS_Tools'
require 'LIBIS_Ingester'

require 'fileutils'

module LIBIS
  module Ingester

    class Submitter < ::LIBIS::Workflow::Task
      parameter login_name: nil,
                description: 'Rosetta staff user login name.'
      parameter login_pass: nil,
                description: 'Rosetta staff user password.'
      parameter login_inst: nil,
                description: 'Rosetta institution.'
      parameter flow_id: nil,
                description: 'Id of the material flow to use.'
      parameter producer_id: nil,
                description: 'Id of the producer to use.'

      def process(item)
        check_item_type ::LIBIS::Ingester::Run, item

        check_ingestable(item)

      end

      def check_ingestable(item)
        item.properties[:ingest_sub_dir] ?
            submit_item(item) :
            item.items.map { |i| check_ingestable(i) }
      end

      def submit_item(item)
        debug "Found ingestable item. Subdir: #{item.properties[:ingest_sub_dir]}", item
        rosetta = LIBIS::Tools::Webservices::Rosetta.new
        handle = rosetta.login(options[:login_name], options[:login_pass], options[:login_inst])
        raise LIBIS::WorkflowAbort, 'Could not log in into Rosetta.' unless handle

        deposit_result = rosetta.deposit_service.submit(
            options[:flow_id],
            options[item.properties[:ingest_sub_dir]],
            options[:producer_id]
        )
        raise LIBIS::WorkflowError, "SIP deposit failed: #{deposit_result[:error]}" if deposit_result[:error]

        item.properties[:ingest_sip] = deposit_result['ser:deposit_result']['ser:sip_id']
        item.properties[:ingest_dip] = deposit_result['ser:deposit_result']['ser:deposit_activity_id']
        item.save
      end

    end
  end
end
