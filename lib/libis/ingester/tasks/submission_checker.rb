# encoding: utf-8

require 'libis-services'

require 'libis/ingester/run'

require 'fileutils'

module Libis
  module Ingester

    class SubmissionChecker < ::Libis::Ingester::Task

      parameter item_types: [Libis::Ingester::Run], frozen: true

      protected

      def process(item)
        check_ingestable(item)
      end

      private

      def check_ingestable(item)
        item.properties[:ingest_sip] ?
            check_item(item) :
            item.items.map { |i| check_ingestable(i) }
      end

      def check_item(item)
        # noinspection RubyResolve
        rosetta = Libis::Services::Rosetta::Service.new(Libis::Ingester::Config.base_url, Libis::Ingester::Config.pds_url)
        producer_info = item.get_run.producer
        handle = rosetta.login(producer_info[:agent], producer_info[:password], producer_info[:institution])
        raise Libis::WorkflowAbort, 'Could not log in into Rosetta.' if handle.nil?
        sip_handler = rosetta.sip_service
        sip_info = sip_handler.get_info(item.properties[:ingest_sip])
        item.properties[:ingest_status] = sip_info.to_hash
        info "SIP: #{sip_info.id} - Module: #{sip_info.module} Stage: #{sip_info.stage} Status: #{sip_info.status}"
      end

    end
  end
end
