#
# Auto-generated by jaxb2ruby v0.0.1 on 2018-11-08 16:35:10 +0100
# https://github.com/sshaw/jaxb2ruby
#

require "roxml"

module Libis module Ingester module Teneo


class CollectionDefault 
  include ROXML

  xml_namespaces "ns1" => "https://teneo.libis.be/schema/pip"

  xml_name "ns1:collection_default"



  
      xml_accessor :navigate?, :from => "@navigate", :required => false
    
  
      xml_accessor :publish?, :from => "@publish", :required => false
    
  
end


end end end
