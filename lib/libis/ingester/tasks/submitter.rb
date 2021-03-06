# encoding: utf-8

require 'libis-services'

require 'libis/ingester/run'

require 'fileutils'

module Libis
  module Ingester

    class Submitter < ::Libis::Ingester::Task

      taskgroup :ingester

      parameter recursive: true, frozen: true

      protected

      def pre_process(item)
        skip_processing_item unless item.properties['ingest_sub_dir']
      end

      def process(item)
        submit_item(item)
        stop_processing_subitems
      end

      private

      def submit_item(item)
        if item.properties['ingest_sip']
          debug "Item already submitted: Deposit ##{item.properties['ingest_dip']} SIP: #{item.properties['ingest_sip']}", item
          return
        end
        debug "Found ingestable item. Subdir: #{item.properties['ingest_sub_dir']}", item
        producer_info = item.get_run.producer
        unless @deposit_service
          @deposit_service = Libis::Services::Rosetta::DepositHandler.new(Libis::Ingester::Config.base_url)
          @deposit_service.authenticate(producer_info[:agent], producer_info[:password], producer_info[:institution])
        end

          deposit_result = @deposit_service.submit(
              item.get_run.material_flow,
              File.join(item.get_run.ingest_sub_dir, item.properties['ingest_sub_dir']),
              producer_info[:id],
              item.get_run.id
          )
          debug 'Deposit result: %s', item , deposit_result
          item.properties['ingest_sip'] = deposit_result[:sip_id]
          item.properties['ingest_dip'] = deposit_result[:deposit_activity_id]
          item.properties['ingest_date'] = deposit_result[:creation_date]
          item.save!

        info "Deposit ##{item.properties['ingest_dip']} done. SIP: #{item.properties['ingest_sip']}", item
      rescue Libis::Services::ServiceError => e
        raise Libis::WorkflowError, "SIP deposit failed: #{e.message}"
      rescue Exception => e
        raise Libis::WorkflowError, "SIP deposit failed: #{e.message} @ #{e.backtrace.first}"
      end

    end
  end
end
