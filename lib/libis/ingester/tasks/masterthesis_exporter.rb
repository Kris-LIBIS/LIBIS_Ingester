require 'fileutils'

require 'libis/tools/xml_document'

require 'libis-ingester'
require 'libis/ingester/ftps_service'

module Libis
  module Ingester

    class MasterthesisExporter < ::Libis::Ingester::Task

      parameter ftp_host: 'ftpsap.cc.kuleuven.be',
                description: 'FTP host where theses are uploaded.'
      parameter ftp_port: 990,
                description: 'FTP port number.'
      parameter ftp_user: '',
                description: 'FTP user account.'
      parameter ftp_password: '',
                description: 'FTP password.'
      parameter done_dir: '/masterproef/test',
                description: 'Path where theses done files are stored.'
      parameter export_dir: '.', description: 'Directory where the exported XML files will be copied'
      parameter item_types: ['Libis::Ingester::IntellectualEntity']
      parameter recursive: true, frozen: true

      protected

      def process(item)
        export_item(item)
        stop_processing_subitems
      end

      private

      # @param [Libis::Ingester::IntellectualEntity] item
      def export_item(item)
        identifier = item.properties['identifier']
        unless item.pid
          warn "Thesis #{identifier} was not ingested fully."
          return
        end

        rep = item.representation('Archive')
        unless rep
          error 'Cannot find archive representation.', item
          return
        end

        xml_item = rep.files.find { |file| file.name == 'e_thesis.xml' }
        unless xml_item
          error 'Cannot find XML file item in representation', rep
        end

        xml_file = xml_item.fullpath
        xml_doc = Libis::Tools::XmlDocument.open(xml_file)
        xml_doc.add_node :pid, item.pid, xml_doc.get_node('/proeven/proef')

        FileUtils.mkdir_p(parameter(:export_dir))
        xml_path = File.join(parameter(:export_dir), "#{identifier}.xml")
        xml_doc.save(xml_path)
        debug 'XML document saved in %s.', item, xml_path

        storage = DomainStorage.where(domain: 'Masterthesis').find_by(name: 'Loaded')
        storage.data[identifier] = { date: DateTime.now.iso8601, pid: item.pid }
        storage.save!
        debug 'Item %s saved in persistent storage', item, identifier

        @ftp_service ||= Libis::Ingester::FtpsService.new(
            parameter(:ftp_host), parameter(:ftp_port), parameter(:ftp_user), parameter(:ftp_password)
        )
        done_file = File.join(parameter(:done_dir), "#{identifier}.in")
        @ftp_service.put_file(
            done_file,
            ["Geingest op #{Time.now.strftime('%d/%m/%Y')} met id #{item.pid}."]
        )
        debug 'Done file created in %s.', item, done_file
      end

    end
  end
end