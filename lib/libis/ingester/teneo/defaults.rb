#
# Auto-generated by jaxb2ruby v0.0.1 on 2018-11-02 00:50:18 +0100
# https://github.com/sshaw/jaxb2ruby
#

require "roxml"
require "libis/ingester/teneo/collection_default"
require "libis/ingester/teneo/ie_default"
require "libis/ingester/teneo/metadata_default"

module Libis module Ingester module Teneo


class Defaults 
  include ROXML

  xml_namespaces "ns1" => "https://teneo.libis.be/schema"

  xml_name "ns1:defaults"

          xml_accessor :metadata, :as => Libis::Ingester::Teneo::MetadataDefault, :from => "ns1:metadata", :required => false
          xml_accessor :collection, :as => Libis::Ingester::Teneo::CollectionDefault, :from => "ns1:collection", :required => false
          xml_accessor :ie, :as => Libis::Ingester::Teneo::IeDefault, :from => "ns1:ie", :required => false


  
end


end end end