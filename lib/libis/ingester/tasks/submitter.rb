# encoding: utf-8

require 'libis-services'

require 'libis/ingester/run'

require 'fileutils'

module Libis
  module Ingester

    class Submitter < ::Libis::Ingester::Task

      parameter recursive: true, frozen: true
      parameter subitems: true, frozen: true

      protected

      def pre_process(item)
        skip_processing_item unless item.properties[:ingest_sub_dir]
      end

      def process(item)
        submit_item(item)
        stop_processing_subitems
      end

      private

      def submit_item(item)
        debug "Found ingestable item. Subdir: #{item.properties[:ingest_sub_dir]}", item
        # noinspection RubyResolve
        rosetta = Libis::Services::Rosetta::Service.new(Libis::Ingester::Config.base_url, Libis::Ingester::Config.pds_url)
        producer_info = item.get_run.producer
        handle = rosetta.login(producer_info[:agent], producer_info[:password], producer_info[:institution])
        raise Libis::WorkflowAbort, 'Could not log in into Rosetta.' if handle.nil?

        ingest_dir = File.join(item.get_run.ingest_sub_dir, item.properties[:ingest_sub_dir])
        begin
          deposit_result = rosetta.deposit_service.submit(
              item.get_run.material_flow,
              ingest_dir,
              producer_info[:id]
          )
          item.properties[:ingest_sip] = deposit_result[:sip_id]
          item.properties[:ingest_dip] = deposit_result[:deposit_activity_id]
          item.properties[:ingest_date] = deposit_result[:creation_date]
          item.save
        rescue Libis::Services::ServiceError => e
          raise Libis::WorkflowError, "SIP deposit failed: #{e.message}"
        end

        info "Deposit ##{item.properties[:ingest_dip]} done. SIP: #{item.properties[:ingest_sip]}"
      end

    end
  end
end
