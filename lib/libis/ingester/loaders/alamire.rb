require 'libis/ingester/task'
module Libis
  module Ingester
    module Loader
      class Alamire < Libis::Ingester::Task
        taskgroup :loader
        description 'Loader for creating a PIP for Alamire'

        help <<-STR.align_left
        This loader will parse a directory and an Excel file and generate a Teneo PIP (Pre-Ingest Package) that can be 
        ingested in Teneo.

        Each TIFF and EIP file in the folder will be processed and it's name scanned for an object name. The object name
        will be the part of the file name before the first separator character. The part after the first separator will
        become the file's label.  
         
        and for each line an IE will be created. The data files will be extracted from the ACP file and the Scope ID in 
        the XLS will be used to retrieve the metadata for the IE.
        STR

        parameter xls_file: nil,
                  description: 'XLS file with IE information parsed from the ACP XML file.'

        parameter acp_dir: nil,
                  description: 'The folder where the ACP (Alfresco Content Package) export file was extracted.'

        parameter item_types: [Libis::Ingester::Run], frozen: true


      end
    end
  end
end