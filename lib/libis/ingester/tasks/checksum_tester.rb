# encoding: utf-8

require 'LIBIS_Tools'
require 'LIBIS_Workflow'

module LIBIS
  module Ingester

    class ChecksumTester < ::LIBIS::Workflow::Task

      parameter checksum_type: nil,
                description: 'Checksum type to use.',
                constraint: ::LIBIS::Tools::Checksum::CHECKSUM_TYPES.map { |x| x.to_s }
      parameter checksum_file: nil,
                description: 'File with pairs of file names and checksums.'

      def process(item)
        return unless item.is_a? ::LIBIS::Ingester::FileItem

        check_exists item
        check_checksum item
      end

      def check_exists(item)
        raise ::LIBIS::WorkflowError, "File '#{item.filepath}' does not exist." unless File.exists? item.filepath
      end

      def check_checksum(item)

        checksum_type = options[:checksum_type]

        debug 'Checking checksum.'

        if checksum_type.nil?
          self.class.parameters[:checksum_type].constraint.each do |x|
            test_checksum(item, x) if item.checksum(x)
          end
        else
          checksumfile_path = options[:checksum_file]
          if checksumfile_path
            unless File.exist?(checksumfile_path)
              warn "Checksum file '#{checksumfile_path}' not found. Skipping check."
              return
            end
            lines = %x(grep #{item.name} #{checksumfile_path})
            if lines.empty
              warn "File '#{item.name}' not found in checksum file ('#{checksumfile_path}'. Skipping check."
              return
            end
            file_checksum = ::LIBIS::Tools::Checksum.hexdigest(item.filepath, checksum_type.to_sym)
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
            raise ::LIBIS::WorkflowError, "#{checksum_type} checksum file test failed for #{item.filepath}."
          else
            test_checksum(item, checksum_type)
          end

        end
      end

      def test_checksum(item, checksum_type, expected = nil)
        expected ||= item.checksum(checksum_type)
        checksum = ::LIBIS::Tools::Checksum.hexdigest(item.filepath, checksum_type.to_sym)
        return if expected == checksum
        raise ::LIBIS::WorkflowError, "Calculated #{checksum_type} checksum does not match previously calculated checksum."
      end


    end

  end
end
