#!/usr/bin/env ruby

require 'highline'
@hl = HighLine.new

@options = {}

APP_DIR = File.absolute_path(File.join(File.dirname(__FILE__), '..'))

def pid_file_name(instance)
  File.join(APP_DIR, "sidekiq#{instance.empty? ? '' : "_#{instance}"}.pid")
end

def log_file_name(instance)
  File.join(APP_DIR, "sidekiq#{instance.empty? ? '' : "_#{instance}"}.log")
end

def get_pid(pid_file = nil)
  return nil unless pid_file && File.exists?(pid_file)
  pid = File.readlines(pid_file).first.strip
  ps = `ps -p #{pid}`.strip
  if ps.empty?
    File.delete(pid_file)
    return nil
  end
  pid.to_i
end

def sidekiq_pid(instance)
  get_pid(pid_file_name(instance))
end

def quiet_sidekiq(instance)
  instance ||= @hl.ask('Instance name: ') { |q| q.validate = /\A[A-Za-z0-9_]*\Z/ }
  return unless (pid = sidekiq_pid(instance))
  puts "Stopping Sidekiq #{instance} process #{pid}."
  dir = Dir.pwd
  Dir.chdir(APP_DIR)
  `bundle exec sidekiqctl quiet #{pid_file_name(instance)}`
  Dir.chdir(dir)
end

def stop_sidekiq(instance)
  instance ||= @hl.ask('Instance name: ') { |q| q.validate = /\A[A-Za-z0-9_]*\Z/ }
  return unless (pid = sidekiq_pid(instance))
  puts "Stopping Sidekiq #{instance} process #{pid}."
  dir = Dir.pwd
  Dir.chdir(APP_DIR)
  `bundle exec sidekiqctl stop #{pid_file_name(instance)} 60`
  Dir.chdir(dir)
  !sidekiq_pid(instance)
end

def start_sidekiq(instance = nil)
  instance ||= @hl.ask('Instance name: ') { |q| q.validate = /\A[A-Za-z0-9_]*\Z/ }
  pid = sidekiq_pid(instance)
  if pid
    puts "Sidekiq #{instance} already running as process #{pid}."
    return false
  end
  dir = Dir.pwd
  Dir.chdir(APP_DIR)
  `bundle exec sidekiq -C config/sidekiq.yml -P #{pid_file_name(instance)} -L #{log_file_name(instance)} -g #{instance} -r ./bin/server.rb`
  Dir.chdir(dir)
  sleep(2)
  pid = sidekiq_pid(instance)
  if pid
    puts "Sidekiq #{instance} started. Process id: #{pid}."
  else
    puts "Sidekiq #{instance} failed to start."
  end
  !!pid
end

def restart_sidekiq(instance)
  instance ||= @hl.ask('Instance name: ') { |q| q.validate = /\A[A-Za-z0-9_]*\Z/ }
  stop_sidekiq(instance)
  start_sidekiq(instance)
end

def get_sidekiqs
  Dir.glob("#{APP_DIR}/sidekiq*.pid").sort.map do |f|
    pid = get_pid(f)
    next unless pid
    status = `ps -fp #{pid} | grep sidekiq`.strip.gsub(/^.*sidekiq[\s0-9.]*/,'').gsub(/\s*$/,'')
    "[#{pid}]: #{status}"
  end
end

def action_menu(instance)
  @hl.choose do |menu|
    menu.prompt = 'Select action: '
    menu.layout = :one_line
    menu.select_by = :index_or_name
    menu.choice('halt') { quiet_sidekiq instance }
    menu.choice('stop') { stop_sidekiq instance; return false }
    menu.choice('restart') { restart_sidekiq instance}
    menu.hidden('') { return false }
  end
  true
end

def select_instance
  @hl.choose do |menu|
    menu.prompt = 'Select instance: '
    menu.header = "\nRunning instances"
    menu.select_by = :index_or_name
    menu.choice('start new instance') { start_sidekiq }
    menu.choice('refresh') {}
    get_sidekiqs.each do |instance|
      menu.choice(instance) do
        inst = instance.gsub(/^\[[\s\d.]+\]:\s*/, '').gsub(/\s*\[.*$/, '')
        loop do
          break unless action_menu(inst)
        end
      end
    end
    menu.hidden('') { return false }
  end
  true
end

loop do
  break unless select_instance
end
