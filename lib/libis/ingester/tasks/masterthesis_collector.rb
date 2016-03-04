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
      parameter ftp_user: '',
                description: 'FTP user account.'
      parameter ftp_password: '',
                description: 'FTP password.'
      parameter ftp_subdir: '/masterproef/out',
                description: 'Path where theses are stored.'
      parameter selection_regex: nil,
                description: 'RegEx for selection only part of the directories'

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
          next unless parameter(:selection_regex).nil? or Regex.new(parameter(:selection_regex)) =~ name
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
        info 'Processing dir %s', dir_name

        work_dir = File.join(@work_dir, dir_name)
        FileUtils.mkpath(work_dir)
        files = ftp_ls(dir)
        files = files.map do |file|
          local_file = File.join(work_dir, File.basename(file))
          ftp_get_file(file, local_file)
          local_file
        end

        xml_file_name = 'e_thesis.xml'
        xml_file = files.find { |file| File.basename(file) == xml_file_name }
        unless xml_file
          error 'XML file missing in %s', dir_name
          #raise Libis::WorkflowError
        end

        xml_doc = Libis::Tools::XmlDocument.open(xml_file)
        proeven = xml_doc.root.search('/proeven/proef')
        warn 'XML file in %s contains multiple theses. Only using first item.', dir_name if proeven.size > 1
        proef = proeven.first

        ie_item = Libis::Ingester::IntellectualEntity.new
        ie_item.name = dir_name
        ie_item.properties['title'] = proef.search('titel1/tekst').map(&:text).map(&:strip).first
        workitem << ie_item
        ie_item.save!
        debug 'Added IE \'%s\'', ie_item.properties['title']

        if ie_item.properties['title'].nil?
          error 'XML entry in does not have a value for titel1/text.', ie_item
          # raise Libis::WorkflowError
          return
        end

        hoofdtekst = proef.search('bestanden/hoofdtekst').map(&:text)

        if hoofdtekst.empty?
          error 'XML file missing a main file entry (bestanden/hoofdtekst).', ie_item
          # raise Libis::WorkflowError
          return
        end

        if hoofdtekst.size > 1
          error 'XML file has multiple a main file entries (bestanden/hoofdtekst).', ie_item
          # raise Libis::WorkflowError
          return
        end

        if hoofdtekst.first.blank?
          error 'XML file has an empty main file entry (bestanden/hoofdtekst).', ie_item
          # raise Libis::WorkflowError
          return
        end

        bijlagen = proef.search('bestanden/bijlage').map(&:text)
        files_from_xml = hoofdtekst + bijlagen

        ok = true

        files_from_xml.each do |fname|
          unless files.any? { |file| File.basename(file) == fname }
            error 'A file \'%s\' listed in the XML is not found on FTP server', ie_item, fname
            ok = false
            next
          end
        end

        files.each do |file|
          fname = File.basename(file)
          unless fname == xml_file_name || files_from_xml.include?(File.basename(file))
            error 'A file \'%s\' was found on the FTP that was not listed in the XML', ie_item, File.basename(file)
            ok = false
            next
          end
          file_item = Libis::Ingester::FileItem.new
          file_item.filename = file
          ie_item << file_item
          debug 'Added file \'%s\'.', ie_item, fname
        end

        # raise Libis::WorkflowError unless ok
        return unless ok

        ie_item.save!
      end

      def ftp_connect
        ftp_disconnect
        @ftp ||= DoubleBagFTPS.new
        @ftp.open_timeout = 10.0
        @ftp.ftps_mode = DoubleBagFTPS::EXPLICIT
        @ftp.connect parameter(:ftp_host), parameter(:ftp_port)
        @ftp.login parameter(:ftp_user), parameter(:ftp_password)
        @ftp.passive = true
        @ftp.read_timeout = 5.0
        debug 'Connected to FTP server.'
      end

      def ftp_disconnect
        return unless @ftp.is_a?(DoubleBagFTPS)
        @ftp.close
      end

      def ftp_check
        begin
          yield
        rescue Errno::ETIMEDOUT
          ftp_connect
          yield
        end
      end

      def ftp_chdir(dir)
        ftp_check do
          @ftp.chdir(dir)
        end
      end

      def ftp_ls(dir)
        ftp_check do
          @ftp.nlst(dir)
        end
      end

      def ftp_get_file(file, local_path)
        ftp_check do
          @ftp.getbinaryfile(file, local_path)
        end
      end

      def is_file?(entry)
        @ftp.size(entry).is_a?(Numeric) ? true : false rescue false
      end
    end
  end
end
