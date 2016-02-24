#!/usr/bin/env ruby
require_relative 'include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  run_opts(opts)
  db_opts(opts)

end.parse!

get_installer
if @options[:delete] || @options[:reset]
  ::Libis::Ingester::Run.each do |run|
    next unless run.check_status(:DONE)
    puts '  ' + run.name
    run.destroy!
  end if @hl.agree('This will delete all runs. OK?', false)
else
  get_run
  @options[:run].destroy! if @hl.agree("I will destroy all evidence of run #{@options[:run].name}. OK?", false)
  exit
end

if @options[:reset] && @hl.agree('This will reset the complete database to its initial state. OK?', false)
  puts 'Clearing database ...'
  @installer.database.clear
end

puts 'Seeding database ...'
@installer.seed_database

puts 'Done.'
