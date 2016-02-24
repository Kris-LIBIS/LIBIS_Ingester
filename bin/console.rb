require_relative 'include'
[
    'site.config.yml',
    '../site.config.yml',
    File.join(File.dirname(File.absolute_path(__FILE__)), '..', 'site.config.yml')
].each do |file|
  next unless File.exist?(file)
  @options[:config] = file
  break
end
get_installer
puts 'Ingester console ready.'