#!/usr/bin/env ruby
require_relative '../lib/libis/ingester/console/include'

require 'fileutils'

@options = {}

APP_DIR = File.absolute_path(File.join(File.dirname(__FILE__), '..'))

def start_process(cmd, *args)
  pid = Process.spawn(cmd, *args)
  Process.wait(pid)
end

def spawn_process(cmd, *args)
  pid = Process.spawn(cmd, *args)
  Process.detach(pid)
  pid
end

def pid_file_name(tag)
  File.join(APP_DIR, "sidekiq#{tag.empty? ? '' : "_#{tag}"}.pid")
end

def log_file_name(tag)
  File.join(APP_DIR, "sidekiq#{tag.empty? ? '' : "_#{tag}"}.log")
end

def get_pid(process)
  pid = process['pid']
  return nil unless check_pid(pid)
  pid
end

def check_pid(pid)
  ps = `ps --no-heading -p #{pid}`.strip
  !ps.empty?
end

def sidekiq_pid(process)
  get_pid(process)
end

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

def stop_sidekiq(process)
  tag = process['tag']
  return unless (pid = sidekiq_pid(process))
  puts "Stopping Sidekiq #{tag} process #{pid}."
  process.stop!
  sleep(0.2)
  0.upto(50).each do
    unless check_pid(pid)
      puts "Sidekiq #{tag} process #{pid} stopped."
      return true
    end
    sleep(0.2)
  end
  puts "Could not stop Sidekiq #{tag} process #{pid}."
  false
ensure
  dir = Dir.pwd
  Dir.chdir(APP_DIR)
  pid_file = pid_file_name(tag)
  File.delete(pid_file) if File.exists?(pid_file)
  Dir.chdir(dir)
end

def start_sidekiq(tag = nil, queue_names = [])
  tag ||= @hl.ask('name: ') { |q| q.validate = /\A[a-zA-Z][a-zA-Z0-9_ ]*\Z/ }
  dir = Dir.pwd
  Dir.chdir(APP_DIR)
  pid_file = pid_file_name(tag)
  if File.exists?(pid_file)
    pid = File.readlines(pid_file).first.strip.to_i
    if check_pid(pid)
      puts "Sidekiq #{tag} already running as process #{pid}."
      return pid
    end
    File.delete(pid_file)
  end

  if queue_names.empty?
    while (queue = select_defined_queue(with_create: true))
      next unless queue.is_a?(Sidekiq::Queue)
      queue_names.member?(queue.name) ? queue_names.delete(queue.name) : queue_names.push(queue.name)
      puts "Selected: #{queue_names}"
    end
  end

  FileUtils.rm(log_file_name(tag), force: true)

  concurrency = @hl.ask('Number of threads: ', Integer) { |q| q.default = 5; q.in = 1..10 }

  options = [
      '-C', 'config/sidekiq.yml',
      '-P', pid_file_name(tag),
      '-L', log_file_name(tag),
      '-g', tag,
      '-c', concurrency.to_s,
      '-r', "#{APP_DIR}/lib/libis/ingester/console/server.rb"
  ]
  queue_names.each { |queue| options << '-q' << queue }
  start_process 'bundle', 'exec', 'sidekiq', *options
  sleep(1)
  0.upto(50).each do
    get_processes.each do |process|
      if process['tag'] == tag
        pid = process['pid']
        if check_pid(pid)
          puts "Sidekiq #{tag} process #{pid} started."
          return pid
        end
      end
    end
    sleep(0.2)
  end
  puts "Sidekiq #{tag} failed to start."
  nil
ensure
  Dir.chdir(dir)
end

def restart_sidekiq(process)
  stop_sidekiq(process)
  start_sidekiq(process['tag'], process['queues'])
end

def list_workers(process)
  format = '%-15s %-15s %-15s %s'
  puts format % %w(thread queue started payload)
  Sidekiq::Workers.new.each do |process_id, thread_id, work|
    next unless process_id == process['identity']
    puts format % [
        thread_id,
        work['queue'],
        work['run_at'],
        work['payload']['args'].map(&:to_s).join(', ')
    ]
  end
end

def action_menu(process)
  menu = {}
  menu[:halt] = Proc.new { quiet_sidekiq process } unless process.stopping?
  menu[:stop] = Proc.new { stop_sidekiq process }
  menu[:restart] = Proc.new { restart_sidekiq process }
  menu[:workers] = Proc.new { list_workers process }
  selection_menu('action', [], hidden: menu, prompt: nil, parent: process['tag'], layout: :one_line)
end

def select_instance
  menu = {'+' => Proc.new { start_sidekiq; true }}
  action = lambda { |process| action_menu(process); true }
  select_process(nil, hidden: menu, proc: action)
end

get_sidekiq

loop do
  break unless select_instance
end
