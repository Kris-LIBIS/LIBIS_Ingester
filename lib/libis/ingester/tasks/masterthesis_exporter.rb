require 'fileutils'

require 'libis/tools/xml_document'

require 'libis-ingester'
require 'libis/ingester/file_service'
require 'libis/ingester/ftps_service'

module Libis
  module Ingester

    class MasterthesisExporter < ::Libis::Ingester::Task

      parameter local_storage: '',
                description: 'Local directory for file storage. If empty, FTP remote storage is used.'
      parameter ftp_host: 'ftpsap.cc.kuleuven.be',
                description: 'FTP host where theses are uploaded.'
      parameter ftp_port: 990,
                description: 'FTP port number.'
      parameter ftp_user: '',
                description: 'FTP user account.'
      parameter ftp_password: '',
                description: 'FTP password.'
      parameter done_dir: '/masterproef/in',
                description: 'Path where theses done files are stored.'
      parameter error_dir: '/masterproef/error',
                description: 'Path where theses error files are stored.'
      parameter remove_input: false,
                description: 'Should input files be removed after successful ingest'
      parameter export_dir: '.', description: 'Directory where the exported XML files will be copied'
      parameter item_types: ['Libis::Ingester::IntellectualEntity'], frozen: true
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

        xml_item = rep.files.find { |file| file.filename == 'e_thesis.xml' }
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

        item.properties['export_file'] = xml_path
        item.save!

        storage = DomainStorage.where(domain: 'Masterthesis').find_by(name: 'Loaded')
        storage.data[identifier] = {date: DateTime.now.iso8601, pid: item.pid}
        storage.save!
        debug 'Item %s saved in persistent storage', item, identifier

        @file_service ||= parameter(:local_storage).blank? ?
            Libis::Ingester::FileService.new(parameter(:local_storage)) :
            Libis::Ingester::FtpsService.new(
                parameter(:ftp_host), parameter(:ftp_port), parameter(:ftp_user), parameter(:ftp_password)
            )
        done_file = File.join(parameter(:done_dir), "#{identifier}.out")
        @file_service.put_file(
            done_file,
            ["Geingest op #{Time.now.strftime('%d/%m/%Y')} met id #{item.pid}."]
        )
        debug 'Done file created in %s.', item, done_file

        error_file = File.join(parameter(:error_dir), "#{identifier}.error")
        if @file_service.exist?(error_file)
          @file_service.del_file(error_file)
          debug 'Error file %s deleted.', item, error_file
        end

        if parameter(:remove_input)
          source_dir = item.properties['source_path']
          @file_service.del_tree(source_dir)
          debug 'Source dir %s deleted.', item, source_dir
        end

      end

    end
  end
end
