#
# Auto-generated by jaxb2ruby v0.0.1 on 2018-10-31 12:00:29 +0100
# https://github.com/sshaw/jaxb2ruby
#

require "roxml"
require "libis/ingester/teneo/metadata/file"
require "libis/ingester/teneo/metadata/search"

module Libis module Ingester module Teneo


class Metadata 
  include ROXML

  xml_namespaces "ns1" => "https://teneo.libis.be/schema"

  xml_name "ns1:metadata"

          xml_accessor :record, :from => "ns1:record", :required => false
          xml_accessor :file, :as => Libis::Ingester::Teneo::Metadata::File, :from => "ns1:file", :required => false
          xml_accessor :search, :as => Libis::Ingester::Teneo::Metadata::Search, :from => "ns1:search", :required => false


  
end


end end end
