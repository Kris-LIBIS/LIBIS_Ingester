#
# Auto-generated by jaxb2ruby v0.0.1 on 2018-10-31 12:00:29 +0100
# https://github.com/sshaw/jaxb2ruby
#

require "roxml"

module Libis module Ingester module Teneo
class Pip

class Property 
  include ROXML

  

  xml_name "Property"


    xml_accessor :content, :from => ".", :required => false

  
      xml_accessor :key, :from => "@key", :required => false
    
  
end

end
end end end
