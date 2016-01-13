#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis-ingester'

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on('-c', '--config CONFIG', 'Config file') do |v|
    options[:config] = v
  end

  opts.on('-d', '--delete', 'Delete runs') do |v|
    options[:delete] = v
  end

  opts.on('-r', '--reset', 'Reset database') do |v|
    options[:reset] = v
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end

end.parse!

puts 'Configuring ...'
::Libis::Ingester.configure do |cfg|
  cfg.logger = ::Logger.new(STDOUT)
  cfg.set_log_formatter
  cfg.logger.level = Logger::DEBUG
end

require 'libis/ingester/installer'

installer = ::Libis::Ingester::Installer.new(options[:config] || 'site.config.yml')

if options[:delete] || options[:reset]
  puts 'Deleting runs ...'
  ::Libis::Ingester::Run.each do |run|
    puts '  ' + run.name
    run.destroy!
  end
end

if options[:reset]
  puts 'Clearing database ...'
  installer.database.clear
end

puts 'Seeding database ...'
installer.seed_database

puts 'Done.'