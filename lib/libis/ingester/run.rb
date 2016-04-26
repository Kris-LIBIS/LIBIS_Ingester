# encoding: utf-8

require 'libis/ingester'
require 'fileutils'

module Libis
  module Ingester

    class Run < ::Libis::Workflow::Mongoid::Run

      field :producer, type: Hash
      field :material_flow
      field :ingest_dir

      set_callback(:destroy, :before) do |document|
        dir = document.ingest_dir
        FileUtils.rmtree dir if dir && !dir.blank? && Dir.exist?(dir)
      end

      set_callback(:destroy, :after) do |document|
        job = document.job
        # noinspection RubyResolve
        job.runs.delete(document)
        job.save!
      end

      def labels
        Array.new
      end

      def labelpath;
        self.name;
      end

      def workflow
        self.job.workflow
      end

      def ingest_model
        self.job.ingest_model
      end

      def producer
        result = self[:producer] || self.job.producer.key_symbols_to_strings
        self[:producer] ||= result unless self.frozen?
        result.key_strings_to_symbols
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
        action = options.delete('action') || :run
        case action.to_sym
          when :run, :restart
            self.options = self.job.input.merge(options)
            self.save!
            self.action = :run
            self.remove_work_dir
            self.remove_items
            self.run :run
          when :retry
            self.action = :retry
            self.run :retry
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
