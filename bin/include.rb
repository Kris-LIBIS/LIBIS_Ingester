#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis-ingester'
require 'libis-workflow'
require 'libis-workflow-mongoid'
require 'libis-format'
require 'libis-services'
require 'libis-tools'

require 'libis/ingester/installer'

require 'highline/import'

@options = {}

def option_menu(title, items)
  if (name = @options["#{title.downcase}_name".to_sym])
    item = items.find_by(name: name)
    if item
      @options[title.downcase.to_sym] = item
      return
    end
  end
  puts ''
  puts title
  puts '_' * title.size
  items.each_with_index { |item, i| puts "#{i}. #{item.name} (id: #{item.id})" }
  item_nr = ask("#{title} number: ", Integer) { |q| q.in = 0...items.size }
  @options[title.downcase.to_sym] = items[item_nr]
end

require 'optparse'

def common_opts(opts)
  opts.on('-c', '--config CONFIG', 'Config file') do |v|
    @options[:config] = v
  end
  opts.on('--version', 'Show version information') do
    puts "Libis::Tools ................ #{Libis::Tools::VERSION}"
    puts "Libis::Format ............... #{Libis::Format::VERSION}"
    puts "Libis::Workflow ............. #{Libis::Workflow::VERSION}"
    puts "Libis::Workflow::Mongoid .... #{Libis::Workflow::Mongoid::VERSION}"
    puts "Libis::Services ............. #{Libis::Services::VERSION}"
    puts "Libis::Ingester ............. #{Libis::Ingester::VERSION}"
    exit
  end
  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end

def db_opts(opts)
  opts.on('-d', '--delete', 'Delete runs') do |v|
    @options[:delete] = v
  end

  opts.on('-r', '--reset', 'Reset database') do |v|
    @options[:reset] = v
  end
end

def user_opts(opts)
  opts.on('-u', '--user USER', 'User name') do |v|
    @options[:user_name] = v
  end
  opts.on('-p', '--password PASSWORD', 'Password') do |v|
    @options[:password] = v
  end
end

def org_opts(opts)
  user_opts(opts)
  opts.on('-o', '--organization NAME', 'Organization name') do |v|
    @options[:organization_name] = v
  end
end

def job_opts(opts)
  org_opts(opts)
  opts.on('-j', '--job NAME', 'Job name') do |v|
    @options[:job_name] = v
  end
end

def run_opts(opts)
  job_opts(opts)
  opts.on('-r', '--run NAME', 'Run name') do |v|
    @options[:run_name] = v
  end

end

def get_installer
  @installer = ::Libis::Ingester::Installer.new(@options[:config] || 'site.config.yml')
end

def get_user
  option_menu('User', Libis::Ingester::User.all) unless @options[:user]

  loop do
    @options[:password] = ask('Password: ') { |q| q.echo = '.' } unless @options[:password]
    break if @options[:user].authenticate(@options[:password])
    @options[:password] = nil
  end
end

def get_org
  get_user
  # noinspection RubyResolve
  option_menu('Organization', @options[:user].organizations)
end

def get_job
  get_org
  # noinspection RubyResolve
  option_menu('Job', @options[:organization].jobs)
end

def get_run
  get_job
  # noinspection RubyResolve
  option_menu('Run', @options[:job].runs)
end

::Libis::Ingester.configure do |cfg|
  cfg.logger = ::Logger.new(STDOUT)
  cfg.set_log_formatter
  cfg.logger.level = Logger::DEBUG
end

