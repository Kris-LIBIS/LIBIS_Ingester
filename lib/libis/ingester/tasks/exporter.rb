require 'fileutils'
require 'mail'

require 'libis/tools/xml_document'

require 'libis-ingester'

module Libis
  module Ingester

    class Exporter < ::Libis::Ingester::Task

      taskgroup :postingester

      description 'Exports the information about ingested data to a file for further processing by other tools.'

      help <<-STR.align_left
        This task will create a file for the run that contains information about each IntellectualEntity and Collection
        object that was created in Rosetta by the ingester. All export files will be created in the directory named by
        the 'export_dir' parameter. The file name is by default derived from the ingest run name, but can be set
        explicitly with the 'export_file_name' parameter.

        The 'export_mail' parameter is filled in, it is expected to contain a comma-separated list of email addresses 
        to send the export file to. The export file will be sent as an email attachment and still needs to be created 
        and will remain on disk until removed. The preivous parameters need therefore be filled in for this to work.

        The export file format default to tab delimited values and can be choosen with the 'export_format' parameter.
        Besides the formentioned TSV format, CSV, XML and YAML formats are supported. For TSV and CSV file formats, the
        user has the option to include a header line or not by setting the 'export_header' parameter to true or false.

        The export file needs to contain at least a 'key' field for each IE or Collection, but other fields can be 
        added. The export file will contain the key field, the PID of the IE or Collection, a URL to access the object
        and the extra fields.

        By default, the key fiels is defined as the object's name, but can be overwritten with the 'export_key' 
        parameter. The value is a Ruby expression that will be evaluated at run-time. Extra field need to be defined in
        the 'extra_keys' parameter. It needs to contain a Hash with header names as keys and corresponding Ruby 
        expressions as values.

        By default, the Collection information is not exported. If this is needed the standard parameter 'item_types'
        needs to be expanded with the Collection class name ('Libis::Ingester::Collection').
      STR

      parameter export_dir: '.', description: 'Directory where the export files will be copied'
      parameter export_file_name: nil, description: 'File name of the export file (default: derived from ingest run name).'
      parameter mail_to: '',
                description: 'E-mail address (or comma-separated list of addresses) to send report to.'
      parameter mail_cc: '',
                description: 'E-mail address (or comma-separated list of addresses) to send report to in cc.'
      parameter export_key: 'item.name',
                description: 'Expression to collect the key value for the export file.'
      parameter extra_keys: {},
                description: 'List of extra keys to add to the export file.'
      parameter export_format: 'tsv',
                description: 'Format of the export file.',
                constraint: %w'tsv csv xml yml'
      parameter export_header: true, description: 'Add header line to export file.'
      parameter item_types: %w(Libis::Ingester::IntellectualEntity)
      parameter recursive: true, frozen: true

      protected

      def process(item)
        case item
          when Libis::Ingester::Collection
            export_collection(item)
          when Libis::Ingester::IntellectualEntity
            export_item(item)
            stop_processing_subitems
          else
            # do nothing
        end
      end

      def post_process(item)
        return unless item.is_a?(Libis::Ingester::Run)
        email_report item
      end

      protected

      # @param [Libis::Ingester::IntellectualEntity] item
      def export_item(item)
        pid = item.pid
        unless pid
          warn "Object #{item.name} was not ingested fully.", item
          return
        end

        export_file = get_export_file(item)

        key = get_key(export_file, item)

        extra = {}
        parameter(:extra_keys).each do |k,v|
          extra[k] = eval(v) rescue ''
        end

        write_export(export_file, key, pid, extra)

        debug 'Item %s with pid %s exported.', key, pid

      end

      # @param [Libis::Ingester::Collection] item
      def export_collection(item)
        pid = item.properties['collection_id']
        unless pid
          warn "Collection #{item.name} was not found/created.", item
          return
        end

        export_file = get_export_file(item)

        key = get_key(export_file, item)

        pid = "col#{pid}"

        extra = {}
        parameter(:extra_keys).each do |k,v|
          extra[k] = eval(v) rescue ''
        end

        write_export(export_file, key, pid, extra)

        debug 'Collection %s with pid %s exported.', key, pid

      end

      def get_key(export_file, item)
        run_item = item.get_run
        unless run_item.nil? || run_item.properties['export_file']
          run_item.properties['export_file'] = export_file
          run_item.save!
        end
        eval(parameter(:export_key))
      end

      def get_export_file(item)
        FileUtils.mkdir_p(parameter(:export_dir))
        file_name = parameter(:export_file_name)
        file_name ||= "#{item.get_run.name}.#{parameter(:export_format)}"
        File.join(parameter(:export_dir), file_name)
      end

      def write_export(export_file, key_value, pid, extra = {})
        # noinspection RubyStringKeysInHashInspection
        data = {
            'KEY' => key_value,
            'PID' => pid,
            'URL' => "http://resolver.libis.be/#{pid}/representation"
        }.merge(extra)
        open(export_file, 'a') do |f|
          case parameter(:export_format).to_sym
            when :tsv
              f.puts data.keys.map { |k| for_tsv(k) }.join("\t") if f.size == 0 && parameter(:export_header)
              f.puts data.values.map { |v| for_tsv(v) }.join("\t")
            when :csv
              f.puts data.keys.map { |k| for_csv(k) }.join(',') if f.size == 0 && parameter(:export_header)
              f.puts data.values.map { |v| for_csv(v) }.join(',')
            when :xml
              f.puts '<?xml version="1.0" encoding="UTF-8"?>' if f.size == 0 && parameter(:export_header)
              f.puts '<item'
              data.each { |k, v| f.puts "  #{for_xml(k.to_s)}=\"#{for_xml(v)}\"" }
              f.puts '/>'
            when :yml
              f.puts '# Ingester export file' if f.size == 0 && parameter(:export_header)
              f.puts '- ' + data.map { |k,v| "#{k}: #{for_yml(v)}" }.join("\n  ")
            else
              #nothing
          end

        end
      end

      def for_tsv(string)
        string =~ /\t\n/ ? "\"#{string.gsub('"', '""')}\"" : string
      end

      def for_csv(string)
        string =~ /,\n/ ? "\"#{string.gsub('"', '""')}\"" : string
      end

      def for_xml(string, type = :attr)
        string.encode(xml: type)
      end

      def for_yml(string)
        string.inspect.to_yaml
      end

      def email_report(item)
        return if parameter(:mail_to).blank?
        mail = Mail.new
        mail.from 'teneo.libis@gmail.com'
        mail.to parameter(:mail_to)
        mail.cc parameter(:mail_cc) unless parameter(:mail_cc).blank?
        mail.subject 'Ingest complete.'
        mail.body "The ingest '#{item.name}' finished successfully. Please find the ingest summary in attachment."
        mail.add_file get_export_file(item)
        mail.deliver!
        debug "Report sent to #{parameter(:mail_to)}#{parameter(:mail_cc).blank? ? '' : " and #{parameter(:mail_cc)}"}."
      rescue Timeout::Error => e
        warn "Ingest report could not be sent by email. The report can be found here: #{get_export_file(item)}"
      end

    end
  end
end
