# encoding: utf-8

require 'libis/ingester'
require 'fileutils'

module Libis
  module Ingester

    class Run
      include ::Libis::Workflow::Mongoid::Run
      store_in collection: 'ingest_runs'

      field :producer, type: Hash
      field :material_flow
      field :ingest_dir

      belongs_to :job, inverse_of: :runs, class_name: Libis::Ingester::Job.to_s
      belongs_to :ingest_model, inverse_of: :runs, class_name:  Libis::Ingester::IngestModel.to_s

      item_class Libis::Ingester::Item.to_s

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

    end

  end
end
