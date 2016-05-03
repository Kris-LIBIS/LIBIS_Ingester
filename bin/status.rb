#!/usr/bin/env ruby
require_relative '../lib/libis/ingester/console/include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  run_opts(opts)

end.parse!

get_initializer

def item_status(item)
  puts "Status overview for [#{item.class.name.split('::').last}] '#{item.name}':"
  format_str = '%-30s %-20s %-20s %-10s %s'
  puts format_str % %w'Task Started Updated Status Progress'
  puts '-' * 90
  item.reload.status_log.each do |status|
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
end

loop do
  break unless select_user
  loop do
    break unless select_organization
    loop do
      break unless select_job
      loop do
        @options[:job].reload_relations
        break unless select_run
        item = @options[:run]
        loop do
          item_status(item)
          menu = { '.' => Proc.new { item } }
          menu['+'] = Proc.new { select_item(item) } if item.items.count > 0
          item = selection_menu('action', [], hidden: menu, header: '', prompt: '', layout: :one_line) || item.parent
          break unless item
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
