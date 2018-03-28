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
        html_file = File.join(dir, "#{name}.html")
        status('Run') != :DONE ?
            send_error_log(self.log_filename, csv_file, html_file) :
            send_success_log(self.log_filename, csv_file, html_file)
      end

      protected

      def send_error_log(log_file, csv_file, html_file)
        return unless self.error_to
        log2csv(log_file, csv_file, skip_date: true, filter: 'WEF', trace: true)
        csv2html(csv_file, html_file)
        status_log = csv2html_io(status2csv_io(self))
        mail = Mail.new do
          from 'teneo.libis@gmail.com'
          to self.error_to
          subject "Ingest failed: #{self.name}"
          html_part do
            content_type 'text/html; charset=UTF-8'
            body [
                     "Unfortunately the ingest '#{self.name}' failed. Please find the ingest log in attachment.",
                     "Below is a summary of the error messages.",
                     status_log.string
            ].join("\n")
          end
          add_file csv_file
          add_file html_file
        end.deliver!
        puts "Ingest log sent to #{self.error_to}."
      rescue Exception
        puts "Ingest log file could not be sent by email."
        FileUtils.remove csv_file, force: true
        FileUtils.remove html_file, force: true
      end

      def send_success_log(log_file, csv_file, html_file)
        return unless self.success_to
        log2csv(log_file, csv_file, skip_date: false, filter: 'IWEF')
        csv2html(csv_file, html_file)
        mail = Mail.new
        mail.from 'teneo.libis@gmail.com'
        mail.to self.success_to
        mail.subject "Ingest complete: #{self.name}"
        mail.body "The ingest '#{self.name}' finished successfully. Please find the ingest log in attachment."
        status_log = csv2html_io(status2csv_io(self)).string
        mail.html_part do
          content_type 'text/html; charset=UTF-8'
          body status_log
        end
        mail.add_file csv_file
        mail.add_file html_file
        mail.deliver!
        puts "Ingest log sent to #{self.error_to}."
      rescue Exception
        puts "Ingest log could not be sent by email."
        FileUtils.remove csv_file, force: true
        FileUtils.remove html_file, force: true
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
