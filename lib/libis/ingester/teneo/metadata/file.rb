#
# Auto-generated by jaxb2ruby v0.0.1 on 2018-11-07 11:02:07 +0100
# https://github.com/sshaw/jaxb2ruby
#

require "roxml"

module Libis module Ingester module Teneo
class Metadata

class File 
  include ROXML

  

  xml_name "File"



  
      xml_accessor :path, :from => "@path", :required => true
    
  
      xml_accessor :format, :from => "@format", :required => false
    
  
      xml_accessor :mapping, :from => "@mapping", :required => false
    
  
end

end
end end end
