require 'libis/ingester'
require 'fileutils'
require 'libis/ingester/tasks/base/log_to_csv'
require 'libis/ingester/tasks/base/csv_to_html'
require 'libis/ingester/tasks/base/status_to_csv'

module Libis
  module Ingester

    class Run < ::Libis::Workflow::Mongoid::Run
      include Libis::Ingester::Base::Log2Csv
      include Libis::Ingester::Base::Csv2Html
      include Libis::Ingester::Base::Status2Csv

      field :error_to, type: String
      field :success_to, type: String

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
        self.id
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
            self.clear_status
            self.run :run
          when :retry
            self.action = :retry
            self.run :retry
          else
            #nothing
        end
      end

      def run(action)
        super(action)
        dir = File.dirname(self.log_filename)
        name = File.basename(self.log_filename, '.*')
        csv_file = File.join(dir, "#{name}.csv")
        status('Run') != :DONE ?
            send_error_log(self.log_filename, csv_file) :
            send_success_log(self.log_filename, csv_file)
      end

      protected

      def send_error_log(log_file, csv_file)
        return unless self.error_to
        log2csv(log_file, csv_file, skip_date: true, filter: 'WEF', trace: true)
        mail = Mail.new
        mail.from 'teneo.libis@gmail.com'
        mail.to parameter(:error_to)
        mail.subject 'Ingest failed.'
        mail.body "Unfortunately the ingest '#{self.name}' failed. Please find the ingest log in attachment."
        mail.body "Below is a summary of the error messages."
        mail.html_part do
          content_type 'text/html; charset=UTF-8'
          body csv2html_io(status2csv_io(item)).string
        end
        log2csv(self.log_filename, csv_file, skip_date: false, filter: 'DIWEF', trace: true)
        mail.add_file csv_file
        mail.deliver!
        debug "Error report sent to #{parameter(:error_to)}."
      rescue Timeout::Error => e
        warn "Error log file could not be sent by email. The error log file can be found here: #{csv_file}"
      end

      def send_success_log(log_file, csv_file)
        return unless self.success_to
        log2csv(log_file, csv_file, skip_date: false, filter: 'IWEF')
        mail = Mail.new
        mail.from 'teneo.libis@gmail.com'
        mail.to parameter(:success_to)
        mail.subject 'Ingest complete.'
        mail.body "The ingest '#{self.name}' finished successfully. Please find the ingest log in attachment."
        mail.html_part do
          content_type 'text/html; charset=UTF-8'
          body csv2html_io(status2csv(self)).string
        end
        mail.add_file csv_file
        mail.deliver!
        debug "Error report sent to #{parameter(:error_to)}."
      rescue Timeout::Error => e
        warn "Error report could not be sent by email. The report can be found here: #{csv_file}"
      end

      def remove_work_dir
        wd = self.work_dir
        FileUtils.rmtree wd if wd && !wd.blank? && Dir.exist?(wd)
      end

      def remove_items
        self.get_items.each do |item|
          item.destroy!
        end
        self.items.clear
      end

      def clear_status
        self.status_log.clear
      end

    end

  end
end
