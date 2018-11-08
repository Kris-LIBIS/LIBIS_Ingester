require 'libis-tools'
require 'libis-metadata'
require 'libis-workflow'
require 'libis-ingester'

require 'libis/ingester/file_service'
require 'libis/ingester/ftps_service'

require 'set'

module Libis
  module Ingester

    class MasterthesisCollector < Libis::Ingester::Task

      taskgroup :collector

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
      parameter ftp_subdir: '/masterproef/out',
                description: 'Path where theses are stored.'
      parameter ftp_errdir: '/masterproef/error',
                description: 'Path where theses errors are stored.'
      parameter selection_regex: nil,
                description: 'RegEx for selection only part of the directories'

      parameter dc_institution: 'K.U.Leuven',
                description: 'Institution name to be used in the DC metadata'
      parameter dc_location: 'Leuven',
                description: 'Location name to be used in the DC metadata'

      parameter item_types: [Libis::Ingester::Run], frozen: true

      protected

      KUL_ID = '50000050'

      # Process the input directory on the FTP server for new material
      # @param [Libis::Ingester::Run] item
      def process(item)
        @work_dir = item.work_dir
        storage = DomainStorage.where(domain: 'Masterthesis').find_or_create_by(name: 'Loaded')
        loaded = storage.data
        @file_service ||= parameter(:local_storage).blank? ?
                              Libis::Ingester::FtpsService.new(
                                  parameter(:ftp_host), parameter(:ftp_port), parameter(:ftp_user), parameter(:ftp_password)
                              ) :
                              Libis::Ingester::FileService.new(parameter(:local_storage))
        dirs = @file_service.ls parameter(:ftp_subdir)
        dirs.each do |dir|
          next if @file_service.is_file?(dir)
          name = File.basename(dir)
          next unless parameter(:selection_regex).nil? or Regexp.new(parameter(:selection_regex)) =~ name
          if loaded[name]
            warn 'Thesis found that is already ingested: \'%s\' [%s]', name, loaded[name]
            next
          end
          process_dir(dir)
        end
      end

      private

      # noinspection RubyResolve

      # Process one FTP directory
      # @param [String] dir FTP directory to process
      def process_dir(dir)
        dir_name = File.basename(dir)
        debug 'Processing dir %s', dir_name

        # Check if we already created an IE for this directory
        if workitem.items.find_by(name: dir_name)
          debug 'Skipping dir %s as it is already processed: IE exists in run', dir_name
          return
        end

        # Copy all files to local work dir
        work_dir = File.join(@work_dir, dir_name)
        FileUtils.mkpath(work_dir)
        files = @file_service.ls(dir)
        files = files.map do |file|
          local_file = File.join(work_dir, File.basename(file))
          @file_service.get_file(file, local_file)
          local_file
        end

        # Get the XML file
        xml_file_name = 'e_thesis.xml'
        xml_file = files.find {|file| File.basename(file) == xml_file_name}
        unless xml_file
          error 'XML file missing in %s', dir_name
          @file_service.put_file(File.join(parameter(:ftp_errdir), "#{dir_name}.error"), ['XML file missing in %s' % dir_name])
          return
        end

        # Load and parse the XML file
        xml_doc = Libis::Tools::XmlDocument.open(xml_file)
        xml_doc.save(xml_file) # Fix the bad XML that SAP program provides

        proef, files_from_xml = check_thesis(dir_name, files, xml_doc, xml_file_name)

        unless proef
          @file_service.put_file(File.join(parameter(:ftp_errdir), "#{dir_name}.error"), files_from_xml)
          return
        end

        # Check AccessRight
        embargo = xml_doc['//embargo'].to_i
        pub = !(xml_doc.embargo('isPubliek').blank?)
        instelling_id = xml_doc['//instellingId'] || KUL_ID
        # noinspection RubyNestedTernaryOperatorsInspection
        ar_extension = embargo == 0 ? (pub ? 'PUBLIC' : 'IP-RESTRICTED') : 'PROTECTED'
        ar_name = "AR_MT_#{instelling_id}_#{ar_extension}"
        ar = Libis::Ingester::AccessRight.find_by(name: ar_name)
        unless ar
          error "AccessRight #{ar_name} not found.", workitem
          set_status(workitem, :FAILED)
          return
        end

        # Create IE for thesis
        ie_item = Libis::Ingester::IntellectualEntity.new
        ie_item.name = dir_name
        ie_item.label = xml_doc['//titel1/tekst'].strip
        ie_item.access_right = ar
        ie_item.properties['source_path'] = dir
        ie_item.properties['identifier'] = dir_name
        ie_item.properties['user_a'] = 'Ingest from SAP'
        ie_item.properties['user_b'] = xml_doc['//voorkeurbib']

        # Build Dublin Core record from the rest of the XML
        ie_item.metadata_record_attributes = {
            format: 'DC',
            data: create_metadata(proef, dir_name, instelling_id).to_xml
        }

        # Save item
        workitem << ie_item

        debug 'Added IE %s \'%s\'', dir_name, ie_item.properties[:title]

        # add files to IE
        files_from_xml.each do |fname|
          file = files.find {|f| File.basename(f) == fname}
          file_item = Libis::Ingester::FileItem.new
          file_item.filename = file
          ie_item << file_item
          debug 'Added file \'%s\'.', ie_item, fname
        end

        # finally add the XML file
        xml_item = Libis::Ingester::FileItem.new
        xml_item.filename = xml_file
        ie_item << xml_item
        debug 'Added XML file.', ie_item

        # Save item
        ie_item.save!
      end

      def check_error(errors, msg, *args)
        errors << (msg % args)
        error msg, *args
        false
      end

      def check_thesis(dir_name, files, xml_doc, xml_file_name)
        check = true
        errors = []

        proeven = xml_doc.root.search('/proeven/proef')
        if proeven.size == 0
          check_error errors, 'XML file in %s does not contain a thesis.', dir_name
          return false
        end

        check = check_error errors, 'XML file in %s contains multiple theses.', dir_name if proeven.size > 1

        proef = proeven.first

        # check it item has title
        if xml_doc['//titel1/tekst'].strip.blank?
          check = check_error errors, 'XML entry for %s in does not have a value for titel1/text.', dir_name
        end

        # check if files in FTP dir and XML file match
        hoofdtekst = proef.search('bestanden/hoofdtekst').map(&:text)

        if hoofdtekst.empty?
          check = check_error errors, 'XML file for %s missing a main file entry (bestanden/hoofdtekst).', dir_name
        end

        if hoofdtekst.size > 1
          check = check_error errors, 'XML file for %s has multiple a main file entries (bestanden/hoofdtekst).', dir_name
        end

        if hoofdtekst.first.blank?
          check = check_error errors, 'XML file for %s has an empty main file entry (bestanden/hoofdtekst).', dir_name
        end

        bijlagen = proef.search('bestanden/bijlage').map(&:text)
        files_from_xml = []
        files_from_xml += hoofdtekst
        files_from_xml += bijlagen

        files_from_xml.each do |fname|
          unless files.any? {|file| File.basename(file) == fname}
            check = check_error errors, 'The file \'%s\' listed in the XML for %s is not found on FTP server', fname, dir_name
            next
          end
        end

        files.each do |file|
          fname = File.basename(file)
          unless fname == xml_file_name || files_from_xml.include?(File.basename(file))
            check = check_error errors, 'The file \'%s\' was found on the FTP in %s that was not listed in the XML', File.basename(file), dir_name
            next
          end
        end

        # check if all file entries have a unique name
        unless files_from_xml.size == files_from_xml.uniq.size
          files_from_xml.select {|fname| files_from_xml.count(fname) > 1}.uniq.each do |fname|
            check = check_error errors, 'The file \'%s\' is referenced more than once in the XML file for %s', fname, dir_name
          end
        end

        check ? [proef, files_from_xml] : [false, errors]
      end

      # noinspection RubyResolve
      # @param [Nokogiri::XML::Node] proef source xml data
      # @param [String] id identifier
      def create_metadata(proef, id, instelling_id)
        kul_master = (instelling_id == KUL_ID)
        pub_date = DateTime.now.year
        xml = ::Libis::Metadata::DublinCoreRecord.new
        xml.identifier = "#{id}"
        xml.title = proef.at('titel1').at('tekst').text.strip
        add_node(xml, :creator) {"#{proef.at('stdnaam').text.strip}, #{proef.at('stdvoornaam').text.strip} (author)"}
        add_node(xml, :description) {"Dissertation note: Diss #{kul_master ? 'Master ': ''}(#{proef.at('opleidingnaam').text.strip})"}
        add_node(xml, :publisher) {
          "#{parameter(:dc_location)}: #{parameter(:dc_institution)}. " +
              "#{proef.at('faculteitnaam').text.strip}, #{pub_date}"
        } if kul_master
        proef.xpath('promotoren/promotor').each do |promotor|
          add_node(xml, 'contributor!') {
            "#{promotor.at('naam').text.strip}, #{promotor.at('voornaam').text.strip} (thesis advisor)"
          }
        end
        proef.xpath('copromotoren/copromotor').each do |promotor|
          add_node(xml, 'contributor!') {
            "#{promotor.at('naam').text.strip}, #{promotor.at('voornaam').text.strip} (thesis advisor)"
          }
        end
        xml.source = "#{id}"
        add_node(xml, :rights) {
          "#{parameter(:dc_institution)}. #{proef.at('faculteitnaam').text.strip} (degree grantor)"
        } if kul_master
        xml.date = "#{pub_date}"
        xml
      end

      def add_node(xml, node_name)
        value = yield
        node_name = "#{node_name.to_s}=" unless node_name.to_s[-1] == '!'
        xml.send(node_name, value)
      rescue
        warn "Could not create metadata field: #{node_name} for #{xml.identifier.text}"
      end

    end
  end
end
