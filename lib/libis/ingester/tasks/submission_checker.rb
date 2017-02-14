# encoding: utf-8

require 'libis-services'

require 'libis/ingester/run'

require 'fileutils'

module Libis
  module Ingester

    class SubmissionChecker < ::Libis::Ingester::Task

      taskgroup :ingester

      parameter retry_count: 60
      parameter retry_interval: 60
      parameter recursive: true, frozen: true

      protected

      def pre_process(item)
        skip_processing_item if item.check_status(self.namepath) == :DONE
        skip_processing_item unless item.properties['ingest_sip']
      end

      def process(item)
        check_item(item)
        stop_processing_subitems
      end

      private

      def check_item(item)
        # noinspection RubyResolve
        rosetta = Libis::Services::Rosetta::Service.new(Libis::Ingester::Config.base_url, Libis::Ingester::Config.pds_url)
        producer_info = item.get_run.producer
        rosetta.login(producer_info[:agent], producer_info[:password], producer_info[:institution])
        sip_handler = rosetta.sip_service
        sip_info = sip_handler.get_info(item.properties['ingest_sip'])
        item.properties['ingest_status'] = sip_info.to_hash
        item_status = case sip_info.status
                        when 'FINISHED'
                          :DONE
                        when 'DRAFT', 'APPROVED', 'INPROCESS', 'CREATED', 'WAITING', 'ACTIVE'
                          :ASYNC_WAIT
                        when 'IN_HUMAN_STAGE', 'IN_TA'
                          :ASYNC_HALT
                        else
                          :FAILED
                      end
        info "SIP: #{item.properties['ingest_sip']} - Module: #{sip_info.module} Stage: #{sip_info.stage} Status: #{sip_info.status}", item
        assign_ie_numbers(item, sip_handler.get_ies(item.properties['ingest_sip'])) if item_status == :DONE
        set_status(item, item_status)
      end

      def assign_ie_numbers(item, number_list)
        if item.is_a?(Libis::Ingester::IntellectualEntity)
          ie = number_list.shift
          item.pid = ie.pid if ie
          info "Assigned PID #{item.pid} to IE item.", item
        else
          item.get_items.map {|i| assign_ie_numbers(i, number_list)}
        end
      end

    end
  end
end
