#!/usr/bin/env ruby
require_relative 'include'
require_relative 'delete_lib'
require 'readline'
require 'open3'

def item_status(item)
  puts "Status overview for [#{item.class.name.split('::').last}] '#{item.name}':"
  format_str = '%-30s %-12s %-10s %-20s %-20s %10s'
  puts format_str % %w'Task Progress Status Started Updated Elapsed'
  puts '-' * 107
  item.reload.status_log.inject({}) do |hash, status|
    task = status['task'].gsub(/[^\/]*\//, '- ')
    task = '- ' + task unless task == 'Run'
    data = {
        status: status['status'].to_s.capitalize,
        start: status['created'].localtime,
        end: status['updated'].localtime
    }
    if status['progress']
      data[:progress] = status['progress'].to_s
      data[:progress] += ' of ' + status['max'].to_s if status['max']
    end
    data.delete :start if hash[task]
    (hash[task] ||= {}).merge! data
    hash
  end.each do |task, data|
    data_array = [
        task,
        data[:progress].to_s,
        data[:status],
        data[:start].strftime('%d/%m/%Y %T'),
        data[:end].strftime('%d/%m/%Y %T'),
        time_diff_in_hours(data[:start], data[:end]),
    ]
    puts format_str % data_array
  end
end

def status_menu
  loop do
    break unless select_organization
    loop do
      break unless select_job
      loop do
        @options[:job].reload_relations
        break unless (item = select_run(true))
        # item = @options[:run]
        loop do
          if item.is_a?(Array)
            break if item.blank?
            puts 'Selected:'
            item.each { |run| puts "- #{run.name} - #{run.status_label}" }
            menu = {
                '-' => Proc.new do
                  parent = item[0].parent
                  item.each do |i|
                    delete_run(i, true) if i.is_a?(Libis::Ingester::Run)
                    delete_item(i, true) unless i.is_a?(Libis::Ingester::Run)
                  end if @hl.agree('Destroy all selected items?', false)
                  parent
                end,
                'retry' => Proc.new do
                  queue = select_defined_queue
                  item.each do |run|
                    Libis::Ingester::RunWorker.push_retry_job(run.id.to_s, queue.name) if run.is_a?(Libis::Ingester::Run)
                  end if queue
                  nil
                end
            }
            item = selection_menu('action', [], hidden: menu, header: '', prompt: '', layout: :one_line)
          else
            item_status(item)
            menu = {'.' => Proc.new { item }}
            menu['?'] = Proc.new { item_info(item); item }
            menu['+'] = Proc.new { select_item(item) } if item.items.count > 0
            menu['-'] = Proc.new { delete_run(item); nil } if item.is_a?(Libis::Ingester::Run)
            menu['-'] = Proc.new { delete_item(item); nil } unless item.is_a?(Libis::Ingester::Run)
            menu['log'] = Proc.new do
              run = item.is_a?(Libis::Ingester::Run) ? item : item.get_run
              # noinspection RubyResolve
              pid = Process.spawn 'less', run.log_filename
              wait_for(pid)
              item
            end
            menu['errors'] = Proc.new do
              run = item.is_a?(Libis::Ingester::Run) ? item : item.get_run
              # noinspection RubyResolve
              pid = Process.spawn 'grep', '-En', '"( ERROR | WARN )"', run.log_filename
              wait_for(pid)
              item
            end
            menu['retry'] = Proc.new do
              run = item.is_a?(Libis::Ingester::Run) ? item : item.get_run
              queue = select_defined_queue
              Libis::Ingester::RunWorker.push_retry_job(run.id.to_s, queue.name) if queue
              run
            end
            menu['again'] = Proc.new do
              run = item.is_a?(Libis::Ingester::Run) ? item : item.get_run
              queue = select_defined_queue
              Libis::Ingester::RunWorker.push_restart_job(run.id.to_s, queue.name) if queue
              run
            end
            item = selection_menu('action', [], hidden: menu, header: '', prompt: '', layout: :one_line) || item.parent
          end
          break unless item
        end
        @options[:run] = nil
      end
      @options[:job] = nil
    end
    @options[:organization] = nil
  end
end

def wait_for(pid)
  Process.wait pid
rescue Interrupt
  wait_for pid
end