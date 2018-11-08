# require 'i18n'
# I18n.load_path = Dir['config/locales/*.yml']
# puts I18n.config.locale
# puts I18n.t('params.host.url')

# class Doc < Nokogiri::XML::SAX::Document
#   attr_reader :callback
#
#   def initialize(file, proc = nil)
#     @callback = proc
#     @callback ||= lambda { |code, *args| yield code, *args } if block_given?
#     raise RuntimeError, "No callback" unless callback
#     File.open(file) {|f| Nokogiri::XML::SAX::Parser.new(self).parse(f)}
#   end
#
#   def start_document
#     callback.call(:start_document)
#   end
#
#   def characters(string)
#     callback.call(:characters, string)
#   end
#
#   def start_element(name, attrs = [])
#     callback.call(:start_element, name, attrs)
#   end
#
#   def end_element(name)
#     callback.call(:end_element, name)
#   end
#
# end

require 'awesome_print'
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
# require 'libis/ingester/tasks/acp_parser'
#
# class Tester < Libis::Ingester::AcpParser
#   def parse(xml_file)
#     parse_xml(xml_file, nil)
#   end
#
#   private
#
#   def create_ie(info, _item)
#     ap info
#   end
# end
#
#
# Tester.new(nil).parse('/nas/upload/vlp/T1/T1_fotos.xml')

require 'libis/ingester/teneo/pip'
pip = Libis::Ingester::Teneo::Pip.from_xml(File.read('config/instance1.xml'))
print_pip(pip)

# @param [Libis::Ingester::Teneo::Pip] pip
def print_pip(pip)
  puts 'PIP'
  puts 'id: %s' % pip.id
  puts 'label: %s' % pip.label
  print_config(pip.config) if pip.config
  pip.collections.each {|collection| print_collection(collection)}
  pip.ies.each {|ie| print_ie(ie)}
  puts 'END SIP'
end

# @param [Libis::Ingester::Teneo::Config] config
def print_config(config)
  puts 'CONFIG'
  print_ingest(config.ingest) if config.ingest
  config.metadatas.each {|md| print_md_def(md)}
  puts 'END CONFIG'
end

# @param [Libis::Ingester::Teneo::Config::Ingest] ingest
def print_ingest(ingest)
  puts 'INGEST'
  puts 'END INGEST'
end

# @param [Libis::Ingester::Teneo::Config::Metadata] md
def print_md_def(md)
  puts 'METADATA_DEF'
  puts 'END METADATA_DEF'
end

# @param [Libis::Ingester::Teneo::Collection] collection
def print_collection(collection)
  puts 'COLLECTION'
  puts 'END COLLECTION'
end

# @param [Libis::Ingester::Teneo::Ie] ie
def print_ie(ie)
  puts 'WORK'
  puts 'END WORK'
end