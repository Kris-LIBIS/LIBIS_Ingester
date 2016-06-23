#!/usr/bin/env ruby
require_relative 'include'
require_relative 'delete_lib'

def item_status(item)
  puts "Status overview for [#{item.class.name.split('::').last}] '#{item.name}':"
  format_str = '%-30s %-20s %-20s %-10s %s'
  puts format_str % %w'Task Started Updated Status Progress'
  puts '-' * 90
  item.reload.status_log.each do |status|
    task = status['task'].gsub(/[^\/]*\//, '- ')
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

def status_menu
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
          menu = {'.' => Proc.new { item }}
          menu['+'] = Proc.new { select_item(item) } if item.items.count > 0
          menu['-'] = Proc.new { delete_run(item) ; nil } if item.is_a?(Libis::Ingester::Run)
          menu['log'] = Proc.new do
            run = item.is_a?(Libis::Ingester::Run) ? item : item.get_run
            # noinspection RubyResolve
            File.open(run.log_filename, 'r') do |f|
              lines = f.readlines
              size = lines.size
              lines[-([size, 20].min)..-1].each { |l| puts l } rescue nil
            end rescue nil
            item
          end
          menu['retry'] = Proc.new do
            run = item.is_a?(Libis::Ingester::Run) ? item : item.get_run
            queue = select_defined_queue
            Libis::Ingester::RunWorker.push_retry_job(run.id.to_s, queue.name) if queue
            run
          end
          menu['restart'] = Proc.new do
            run = item.is_a?(Libis::Ingester::Run) ? item : item.get_run
            queue = select_defined_queue
            Libis::Ingester::RunWorker.push_restart_job(run.id.to_s, queue.name) if queue
            nil
          end
          item = selection_menu('action', [], hidden: menu, header: '', prompt: '', layout: :one_line) || item.parent
          break unless item
        end
        @options[:run] = nil
      end
      @options[:job] = nil
    end
    @options[:organization] = nil
  end
end
