require 'libis/ingester/task'
module Libis
  module Ingester
    module Loader
      module Base

        class XlsMapper < Libis::Ingester::Task
          taskgroup :loader
          description 'Loader for directory scanning and Excel mapping'

          help <<-STR.align_left
          This loader will parse a directory and an Excel file and generate a Teneo PIP (Pre-Ingest Package) that can be 
          ingested in Teneo.
  
          The directory tree at parameter 'location' will be parsed and ingest objects will be created for files and
          folders found. The behaviour can be extensively configured with the parameters:

          
          Each TIFF and EIP file in the folder will be processed and it's name scanned for an object name. The object name
          will be the part of the file name before the first separator character. The part after the first separator will
          become the file's label.  
           
          and for each line an IE will be created. The data files will be extracted from the ACP file and the Scope ID in 
          the XLS will be used to retrieve the metadata for the IE.
          STR

          parameter location: nil,
                    description: 'Directory to scan for files.'

          parameter file_selection: nil,
                    description: 'Regular expression to match the file name against. Files not matching the expression will be ignored.'

          parameter spreadheet_file: nil,
                    description: 'Excel mapping file.'



        end
      end
    end
  end
end