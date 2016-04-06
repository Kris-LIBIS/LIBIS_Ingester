#!/usr/bin/env ruby
require_relative 'include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  run_opts(opts)
  db_opts(opts)

end.parse!

get_initializer
if @options[:delete] || @options[:reset]
  ::Libis::Ingester::Run.each do |run|
    next unless run.check_status(:DONE)
    puts '  ' + run.name
    run.destroy!
  end if @hl.agree('This will delete all runs. OK?', false)
else
  loop do
    break unless get_user
    loop do
      break unless get_org
      loop do
        break unless get_job
        loop do
          @options[:job].reload_relations
          break unless get_run
          @options[:run].destroy! if @hl.agree("I will destroy all evidence of run #{@options[:run].name}. OK?", false)
          @options[:job].save!
          @options[:run] = nil
        end
        @options[:job] = nil
      end
      @options[:organization] = nil
    end
    @options[:user] = nil
  end
  exit
end

if @options[:reset] && @hl.agree('This will reset the complete database to its initial state. OK?', false)
  puts 'Clearing database ...'
  @initializer.database.clear
end

puts 'Seeding database ...'
@initializer.seed_database

puts 'Done.'
