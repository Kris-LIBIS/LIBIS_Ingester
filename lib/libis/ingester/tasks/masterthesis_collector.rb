require 'libis-tools'
require 'libis-workflow'
require 'libis-ingester'

require 'libis/ingester/ftps_service'

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
      parameter ftp_errdir: '/masterproef/error',
                description: 'Path where theses errors are stored.'
      parameter selection_regex: nil,
                description: 'RegEx for selection only part of the directories'

      parameter embargo_ar: nil,
                description: 'Access right to use for theses with embargo != 00'

      parameter item_types: [Libis::Ingester::Run], frozen: true

      protected

      # Process the input directory on the FTP server for new material
      # @param [Libis::Ingester::Run] item
      def process(item)
        @work_dir = item.work_dir
        storage = DomainStorage.where(domain: 'Masterthesis').find_or_create_by(name: 'Loaded')
        loaded = storage.data
        @ftp_service ||= Libis::Ingester::FtpsService.new(
            parameter(:ftp_host), parameter(:ftp_port), parameter(:ftp_user), parameter(:ftp_password)
        )
        dirs = @ftp_service.ls parameter(:ftp_subdir)
        dirs.each do |dir|
          next if @ftp_service.is_file?(dir)
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

        # Copy all files to local work dir
        work_dir = File.join(@work_dir, dir_name)
        FileUtils.mkpath(work_dir)
        files = @ftp_service.ls(dir)
        files = files.map do |file|
          local_file = File.join(work_dir, File.basename(file))
          @ftp_service.get_file(file, local_file)
          local_file
        end

        # Get the XML file
        xml_file_name = 'e_thesis.xml'
        xml_file = files.find { |file| File.basename(file) == xml_file_name }
        unless xml_file
          error 'XML file missing in %s', dir_name
          @ftp_service.put_file(File.join(parameter(:ftp_errdir), "#{dir_name}.error"), ['XML file missing in %s' % dir_name])
          return
        end

        # Load and parse the XML file
        xml_doc = Libis::Tools::XmlDocument.open(xml_file)
        xml_doc.save(xml_file) # Fix the bad XML that SAP program provides

        proef, files_from_xml = check_thesis(dir_name, files, xml_doc, xml_file_name)

        unless proef
          @ftp_service.put_file(File.join(parameter(:ftp_errdir), "#{dir_name}.error"), files_from_xml)
          return
        end

        # Create IE for thesis
        ie_item = Libis::Ingester::IntellectualEntity.new
        ie_item.name = dir_name
        ie_item.properties['label'] = xml_doc['//titel1/tekst'].strip
        ie_item.properties['identifier'] = dir_name
        embargo = xml_doc['//embargo'].to_i
        ie_item.properties['access_right'] = parameter(:embargo_ar) if parameter(:embargo_ar) && embargo != 0
        ie_item.properties['user_a'] = 'Ingest from SAP'
        ie_item.properties['user_b'] = xml_doc['//voorkeurbib']

        # Build Dublin Core record from the rest of the XML
        ie_item.metadata_record_attributes = {
            format: 'DC',
            data: create_metadata(proef, dir_name).to_xml
        }

        # Save item
        workitem << ie_item
        ie_item.save!
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
        files_from_xml = hoofdtekst + bijlagen

        files_from_xml.each do |fname|
          unless files.any? { |file| File.basename(file) == fname }
            check = check_error errors, 'A file \'%s\' listed in the XML for %s is not found on FTP server', fname, dir_name
            next
          end
        end

        files.each do |file|
          fname = File.basename(file)
          unless fname == xml_file_name || files_from_xml.include?(File.basename(file))
            check = check_error errors, 'A file \'%s\' was found on the FTP in %s that was not listed in the XML', File.basename(file), dir_name
            next
          end
        end

        check ? [proef, files_from_xml] : [false, errors]
      end

      # noinspection RubyResolve
      # @param [Nokogiri::XML::Node] proef source xml data
      # @param [String] id identifier
      def create_metadata(proef, id)
        pub_date = DateTime.now.year
        xml = ::Libis::Tools::Metadata::DublinCoreRecord.new
        xml.identifier = "#{id}"
        xml.title = proef.at('titel1').at('tekst').text.strip
        add_node(xml, :creator) { "#{proef.at('stdnaam').text.strip}, #{proef.at('stdvoornaam').text.strip} (author)" }
        add_node(xml, :description) { "Dissertation note: Diss Master (#{proef.at('opleidingnaam').text.strip})" }
        add_node(xml, :publisher) { "Leuven: K.U.Leuven. #{proef.at('faculteitnaam').text.strip}, #{pub_date}" }
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
        add_node(xml, :rights) { "K.U.Leuven. #{proef.at('faculteitnaam').text.strip} (degree grantor)" }
        xml.date = "#{pub_date}"
        xml.type! 'BK'
        xml.type! 'Dissertation'
        xml.type! 'Accademic collection'
        xml.type! 'ETD_KUL'
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
