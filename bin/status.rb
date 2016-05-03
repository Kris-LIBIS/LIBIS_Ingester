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
        format_str = '%-30s %-20s %-20s %-10s %s'
        puts format_str % %w'Task Started Updated Status Progress'
        puts '-' * 90
        @options[:run].reload.status_log.each do |status|
          task = status['task'].gsub(/[^\/]*\//,'- ')
          task = '- ' + task unless task == 'Run'
          data = [
              task,
              status['created'].localtime.strftime('%d/%m/%Y %T'),
              status['updated'].localtime.strftime('%d/%m/%Y %T'),
              status['status'].to_s.capitalize,
              ''
          ]
          if status['progress']
            data[4] = status['progress'].to_s
            data[4] += ' of ' + status['max'].to_s if status['max']
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
