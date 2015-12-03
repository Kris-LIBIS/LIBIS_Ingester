# encoding: utf-8

require 'libis-tools'
require 'libis/ingester'

module Libis
  module Ingester

    class ChecksumTester < ::Libis::Ingester::Task

      parameter checksum_type: nil,
                description: 'Checksum type to use.',
                constraint: ::Libis::Tools::Checksum::CHECKSUM_TYPES.map { |x| x.to_s }
      parameter checksum_file: nil,
                description: 'File with pairs of file names and checksums.'

      parameter item_types: [Libis::Ingester::FileItem], frozen: true

      protected

      def process(item)
        check_exists item
        check_checksum item
      end

      private

      def check_exists(item)
        raise ::Libis::WorkflowError, "File '#{item.fullpath}' does not exist." unless File.exists? item.fullpath
      end

      def check_checksum(item)

        checksum_type = parameter(:checksum_type)

        debug 'Checking checksum.'

        if checksum_type.nil?
          self.class.parameters[:checksum_type].constraint.each do |x|
            test_checksum(item, x) if item.checksum(x)
          end
        else
          checksumfile_path = parameter(:checksum_file)
          if checksumfile_path
            unless File.exist?(checksumfile_path)
              checksumfile_path = File.join(File.dirname(item.fullpath), checksumfile_path)
              unless File.exist?(checksumfile_path)
                warn "Checksum file '#{checksumfile_path}' not found. Skipping check."
                return
              end
            end
            lines = %x(grep #{item.name} #{checksumfile_path})
            if lines.empty?
              warn "File '#{item.name}' not found in checksum file ('#{checksumfile_path}'. Skipping check."
              return
            end
            file_checksum = ::Libis::Tools::Checksum.hexdigest(item.fullpath, checksum_type.to_sym)
            test_checksum(item, checksum_type) if item.checksum(checksum_type)
            item.set_checksum(checksum_type, file_checksum)
            # we try to match any line as there may be multiple lines containing the file name. We also check any field
            # on a line as the checksum file format may differ (e.g. Linux vs Windows).
            lines.split.each do |expected|
              begin
                test_checksum item, checksum_type, expected
                return # match found. File is OK.
              rescue
                next
              end
            end
            raise ::Libis::WorkflowError, "#{checksum_type} checksum file test failed for #{item.filepath}."
          else
            test_checksum(item, checksum_type)
          end

        end
      end

      def test_checksum(item, checksum_type, expected = nil)
        expected ||= item.checksum(checksum_type)
        checksum = ::Libis::Tools::Checksum.hexdigest(item.fullpath, checksum_type.to_sym)
        expected ||= item.set_checksum(checksum_type, checksum)
        return if expected == checksum
        raise ::Libis::WorkflowError, "Calculated #{checksum_type} checksum does not match expected checksum."
      end


    end

  end
end
