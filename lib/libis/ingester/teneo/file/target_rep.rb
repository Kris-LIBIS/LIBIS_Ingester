#
# Auto-generated by jaxb2ruby v0.0.1 on 2018-11-08 16:35:10 +0100
# https://github.com/sshaw/jaxb2ruby
#

require "roxml"

module Libis module Ingester module Teneo
class File

class TargetRep 
  include ROXML

  

  xml_name "TargetRep"


    xml_accessor :content, :from => ".", :required => false

  
      xml_accessor :derivative_of, :from => "@derivative_of", :required => false
    
  
end

end
end end end