# encoding: utf-8

require 'date'

require 'libis-tools'
require 'libis/ingester'

require 'libis/ingester/dav_dossier'

module Libis
  module Ingester

    class DavSipCollector < ::Libis::Ingester::Task
      parameter location: nil,
                description: 'Dir location to scan for RMT files.'

      def process(item)
        check_item_type ::Libis::Ingester::Run, item

        dirname = parameter(:location)

        raise RuntimeError, 'No location given.' unless dirname

        debug "Processing DAV dossiers in #{dirname}."

        Dir.glob(File.join(dirname,'*')).each do |filename|
          process_dir(filename, item) if File.directory?(filename)
          process_file(dirname, File.basename(filename), item) if File.file?(filename)
        end
      end

      def process_dir(dirname, parent)
        Dir.entries(dirname).select do |file|
          file =~ /^rmt_#{File.basename(dirname)}\.xml$/i
        end.each do |file|
          process_file dirname, file, parent
        end
      end

      def process_file(dirname, filename, parent)
        process_rmt(dirname, filename, parent) if filename =~ /^rmt_#{File.basename(dirname)}\.xml$/i
      end

      def process_rmt(dir, file, ingest_run)
        dossier = Libis::Ingester::DavDossier.new
        dossier.filename = dir
        ingest_run << dossier

        info = Libis::Tools::XmlDocument.open(File.join(dir,file)).to_hash['RMT_metadata']
        dossier.name = info['folder']['name'].to_s

        debug "Dossier found: #{file.gsub(parameter(:location),'')} - #{dossier.name}"

        file_item = Libis::Ingester::FileItem.new
        file_item.filename = File.join(dir, file)
        dossier << file_item

        objects = info.delete('informationObjects')

        dossier.properties[:disposition] = info['disposition']['scheduledYear'].to_i if info['disposition']
        dossier.properties[:rmt_info] = info

        base_dir = dir
        object_list = objects['informationObject'] rescue nil
        case object_list
          when Array
            object_list.each { |object| create_file_object(base_dir, dossier, object) }
          when Hash
            create_file_object(base_dir, dossier, object_list)
          else
            # no file objects found
            warn 'No file objects found. Dossier is empty!'
        end
        dossier.save!
      end

      protected

      def create_file_object(base_dir, dossier, object)
        # process relative dir and create dir items if necessary
        rel_dir = object['algemeen']['map']
        rel_dirs = rel_dir.to_s.split(/[\/\\]/)
        rel_dirs.shift if rel_dirs.first == '.'
        parent = dossier
        rel_dirs.each do |dir|
          dir_item = parent.items.select { |item| item.name == dir }.first
          dir_item ||= create_dir_item dir, parent
          parent = dir_item
        end

        # get file name and create file item
        filename = object['algemeen']['documentnaam']
        relative_path = File.join(*rel_dirs, filename)
        full_path = File.join(base_dir, relative_path)
        file_item = Libis::Ingester::FileItem.new
        file_item.filename = full_path
        checksum = object['technischeMetadata']['checksum']
        checksum_type = checksum.attributes['algorithm'].gsub('-', '')
        file_item.set_checksum(checksum_type, checksum)
        file_item.properties[:rmt_info] = object
        parent << file_item

        # set file's original creation and modification dates
        ctime = object['algemeen']['datumcreatie']
        mtime = object['algemeen']['datumwijziging']
        File.utime(ctime.to_time, mtime.to_time, file_item.fullpath) rescue nil

        # create file's metadata record
        file_item.properties[:rmt_info] = object
        file_item.metadata = Libis::Ingester::MetadataRecord.new
        dc_record = Libis::Tools::DCRecord.new do |xml|
          xml[:dc].title filename
          if object['beschrijvendeMetadata']
            if object['beschrijvendeMetadata']['auteurs'] && !object['beschrijvendeMetadata']['auteurs'].empty?
              # noinspection RubyResolve
              xml[:dc].contributor object['beschrijvendeMetadata']['auteurs']
            end
            if object['beschrijvendeMetadata']['titel'] && !object['beschrijvendeMetadata']['titel'].empty?
              xml[:dc].description object['beschrijvendeMetadata']['titel']
            end
            if object['beschrijvendeMetadata']['onderwerp'] && !object['beschrijvendeMetadata']['onderwerp'].empty?
              xml[:dc].subject object['beschrijvendeMetadata']['onderwerp']
            end
          end
       end
        file_item.metadata.data = dc_record.root.to_xml
        file_item.metadata.format = 'DC'

        debug "File added: #{file_item.namepath}."

        file_item.save!
        file_item
      end

      def create_dir_item(name, parent)
        dir_item = Libis::Ingester::DirItem.new
        dir_item.filename = name
        parent << dir_item
        dir_item.save!
        dir_item
      end

    end

  end
end
