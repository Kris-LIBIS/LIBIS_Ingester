require 'libis-workflow'
require 'libis-ingester'

require 'double_bag_ftps'

module Libis
  module Ingester

    class MasterthesisCollector < Libis::Ingester::Task

      parameter ftp_host: 'ftpsap.cc.kuleuven.be',
                description: 'FTP host where theses are uploaded.'
      parameter ftp_port: 990,
                description: 'FTP port number.'
      parameter ftp_user: 'plias',
                description: 'FTP user account.'
      parameter ftp_password: 'QiZYnEJSp',
                description: 'FTP password.'
      parameter ftp_subdir: '/masterproef/out',
                description: 'Path where theses are stored.'

      parameter item_types: [Libis::Ingester::Run], frozen: true

      protected

      # @param [Libis::Ingester::Run] item
      def process(item)
        @work_dir = item.work_dir
        loaded = PersistentStorage.where(domain: 'Masterthesis').find_or_create_by(name: 'Loaded')[:data]
        ftp_connect
        dirs = ftp_ls parameter(:ftp_subdir)
        dirs.each do |dir|
          next if is_file?(dir)
          name = File.basename(dir)
          if loaded.has_key?(name)
            warn 'Thesis found that is already ingested: \'%s\' [%s]', name, loaded[name]
            next
          end
          process_dir(dir)
        end
      end

      private

      def process_dir(dir)
        dir_name = File.basename(dir)
        work_dir = File.join(@work_dir, dir_name)
        FileUtils.mkpath(work_dir)
        files = ftp_ls(dir)
        files = files.map do |file|
          local_file = File.join(work_dir, File.basename(file))
          ftp_get_file(file, local_file)
          local_file
        end

        xml_file = files.find { |file| File.basename(file) == 'e_thesis.xml' }
        unless xml_file
          error 'XML file missing in %s', dir_name
          raise Libis::WorkflowError
        end

        xml_doc = Libis::Tools::XmlDocument.open(xml_file)
        proeven = xml_doc.root.search('/proeven/proef')
        warn 'XML file in %s contains multiple theses. Only using first item.', dir_name if proeven.size > 1
        proef = proeven.first

        ie_item = Libis::Ingester::IntellectualEntity.new
        ie_item.name = proef.find('/titel1/tekst').map(&:text).map(&:strip).first
        if ie_item.name.nil?
          error 'XML entry in %s/e_thesis.xml does not have a value for titel1/text.', dir_name
          raise Libis::WorkflowError
        end

        hoofdtekst = proef.find('/bestanden/hoofdtekst').map(&:text)

        if hoofdtekst.empty?
          error 'XML file in %s missing a main file entry (bestanden/hoofdtekst).', dir_name
          raise Libis::WorkflowError
        end

        if hoofdtekst.size > 1
          error 'XML file in %s has multiple a main file entries (bestanden/hoofdtekst).', dir_name
          raise Libis::WorkflowError
        end

        bijlagen = proef.search('/bestanden/bijlagen').map(&:text)
        files_from_xml = hoofdtekst + bijlagen

        files_from_xml.each do |fname|
          unless files.any? { |file| File.basename(file) == fname }
            error 'A file\'%s\' listed in the XML is not found on FTP server in %s', fname, dir_name
            raise Libis::WorkflowError
          end
        end

        ok = true
        files.each do |file|
          next if files_from_xml.include?(File.basename(file))
          error 'A file \'%s\' was found on the FTP in %s that was not listed in the XML', File.basename(file), dir_name
          ok = false
        end
        raise Libis::WorkflowError unless ok

        files_from_xml.each do |fname|
          file = Libis::Ingester::FileItem.new
          file.filename = File.join(dir, fname)
          ie_item << file
        end

        ie_item.save!

      end

      def ftp_connect
        ftp_disconnect
        @ftp ||= DoubleBagFTPS.new
        @ftp.ftps_mode = DoubleBagFTPS::EXPLICIT
        @ftp.connect parameter(:ftp_host), parameter(:ftp_port)
        @ftp.login parameter(:ftp_user), parameter(:ftp_password)
        @ftp.passive = true
        debug 'Connected to FTP server.'
      end

      def ftp_disconnect
        return unless @ftp.is_a?(DoubleBagFTPS)
        @ftp.close
      end

      def ftp_check_connection
        begin
          @ftp.pwd
        rescue Net::FTPError
          ftp_connect
        end
      end

      def ftp_chdir(dir)
        ftp_check_connection
        @ftp.chdir(dir)
      end

      def ftp_ls(dir)
        ftp_check_connection
        @ftp.nlst(dir)
      end

      def ftp_get_file(file, local_path)
        ftp_check_connection
        @ftp.getbinaryfile(file, local_path)
      end

      def is_file?(entry)
        @ftp.size(entry).is_a?(Numeric) ? true : false rescue false
      end
    end
  end
end
