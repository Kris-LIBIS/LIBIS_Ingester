#!/usr/bin/env ruby
require_relative 'include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)

end.parse!

get_installer

puts 'Seeding database ...'
@installer.seed_database

puts 'Done.'
