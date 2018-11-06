#
# Auto-generated by jaxb2ruby v0.0.1 on 2018-11-05 17:13:47 +0100
# https://github.com/sshaw/jaxb2ruby
#

require "roxml"
require "libis/ingester/teneo/collection"
require "libis/ingester/teneo/ie"
require "libis/ingester/teneo/metadata"
require "libis/ingester/teneo/pip/option"
require "libis/ingester/teneo/pip/property"

module Libis module Ingester module Teneo


class Collection 
  include ROXML

  xml_namespaces "ns1" => "https://teneo.libis.be/schema"

  xml_name "ns1:collection"

    
      xml_accessor :properties, :as => [Libis::Ingester::Teneo::Pip::Property], :from => "ns1:property", :required => false
    
      xml_accessor :options, :as => [Libis::Ingester::Teneo::Pip::Option], :from => "ns1:option", :required => false
          xml_accessor :metadata, :as => Libis::Ingester::Teneo::Metadata, :from => "ns1:metadata", :required => false
    
      xml_accessor :collections, :as => [Libis::Ingester::Teneo::Collection], :from => "ns1:collection", :required => false
    
      xml_accessor :ies, :as => [Libis::Ingester::Teneo::Ie], :from => "ns1:ie", :required => false


  
      xml_accessor :navigate?, :from => "@navigate", :required => false
    
  
      xml_accessor :publish?, :from => "@publish", :required => false
    
  
      xml_accessor :id, :from => "@id", :required => true
    
  
      xml_accessor :label, :from => "@label", :required => false
    
  
      xml_accessor :label_template, :from => "@label_template", :required => false
    
  
end


end end end
