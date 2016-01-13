# encoding: utf-8

require 'libis/ingester'
require 'fileutils'

module Libis
  module Ingester

    class Run < ::Libis::Workflow::Mongoid::Run

      field :producer, type: Hash
      field :material_flow
      field :ingest_dir

      belongs_to :ingest_model, inverse_of: :runs, class_name:  Libis::Ingester::IngestModel.to_s

      set_callback(:destroy, :before) do |document|
        dir = document.ingest_dir
        FileUtils.rmtree dir if dir && !dir.blank? && Dir.exist?(dir)
      end

      def workflow
        self.job.workflow
      end

      def producer
        result = self[:producer] || self.job.producer
        self[:producer] ||= result unless self.frozen?
        result
      end

      def material_flow
        result = self[:material_flow] || self.job.material_flow
        self[:material_flow] ||= result unless self.frozen?
        result
      end

      def ingest_dir
        result = self[:ingest_dir] || File.join(self.job.ingest_dir, self.ingest_sub_dir)
        self[:ingest_dir] ||= result unless self.frozen?
        result
      end

      def ingest_sub_dir
        self.name
      end

      def execute(options = {})
        options[:action] = :run unless options[:action]
        case options[:action]
          when :run, :restart
            self.action = :run
            remove_work_dir
            remove_items
            run
          when :continue
            self.action = :continue
            run
          else
            #nothing
        end
      end

      private

      def remove_work_dir
        wd = self.work_dir
        FileUtils.rmtree wd if wd && !wd.blank? && Dir.exist?(wd)
      end

      def remove_items
        self.items.each do |item|
          item.destroy!
        end
        self.items.clear
      end

    end

  end
end
