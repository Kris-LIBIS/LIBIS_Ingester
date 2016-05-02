#!/usr/bin/env ruby
require_relative '../lib/libis/ingester/console/include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  run_opts(opts)

end.parse!

get_initializer

loop do
  break unless select_user
  loop do
    break unless select_organization
    loop do
      break unless select_job
      loop do
        @options[:job].reload_relations
        break unless select_run
        format_str = '%-30s %-20s %-20s %s'
        puts format_str % %w'Task Started Updated Progress'
        puts '-' * 90
        @options[:run].status_log.each do |status|
          task = status['task'].gsub(/[^\/]*\//,'- ')
          task = '- ' + task unless task == 'Run'
          data = [
              task,
              status['created'].strftime('%d/%m/%Y %T'),
              status['updated'].strftime('%d/%m/%Y %T'),
              status['status'].to_s.capitalize
          ]
          if status['status'].to_s != 'DONE' && status['progress']
            x = status['progress'].to_s
            x += ' of ' + status['max'].to_s if status['max']
            data[4] = x
          end
          puts format_str % data
        end
        @options[:run] = nil
      end
      @options[:job] = nil
    end
    @options[:organization] = nil
  end
  exit
end
exit
