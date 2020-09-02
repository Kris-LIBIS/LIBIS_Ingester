#!/usr/bin/env ruby
require_relative 'include'

require 'fileutils'

def quiet_sidekiq(process)
  return unless (pid = sidekiq_pid(process))
  puts "Halting Sidekiq #{process['tag']} process #{pid}."
  process.quiet!
  loop do
    get_processes.each do |p|
      if p['pid'] == pid
        return if p.stopping?
      end
    end
    sleep(0.2)
  end
end

def list_threads(process)
  format = '%-15s %-15s %-25s %s'
  puts format % %w(thread queue started payload)
  Sidekiq::Workers.new.each do |process_id, thread_id, work|
    next unless process_id == process['identity']
    puts format % [
        thread_id,
        work['queue'],
        Time.at(work['run_at']).localtime,
        payload_detail(work['payload']['args'])
    ]
  end
end

def payload_detail(payload_args)
  payload_args.map do |arg|
    next arg.to_s unless arg.is_a?(String)
    run = Libis::Ingester::Run.find_by(id: arg)
    next run.name if run
    arg
  end.join(', ')
end

def action_menu(process)
  menu = {}
  menu[:halt] = Proc.new { quiet_sidekiq process; false } unless process.stopping?
  menu[:threads] = Proc.new { list_threads process; true }
  loop do
    break unless selection_menu('action', [], hidden: menu, prompt: nil, parent: process['tag'], layout: :one_line)
  end
end

def process_menu
  menu = {}
  action = lambda { |process| list_threads(process); action_menu(process); true }
  loop do
    break unless select_process(nil, hidden: menu, proc: action)
  end
end
