#!/usr/bin/env ruby
require_relative 'include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  db_opts(opts)

end.parse!

get_installer

if @options[:delete] || @options[:reset]
  puts 'Deleting runs ...'
  ::Libis::Ingester::Run.each do |run|
    puts '  ' + run.name
    run.destroy!
  end
end

if @options[:reset]
  puts 'Clearing database ...'
  @installer.database.clear
end

puts 'Seeding database ...'
@installer.seed_database

puts 'Done.'
