#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis-ingester'
require 'libis-workflow'
require 'libis-workflow-mongoid'
require 'libis-format'
require 'libis-services'
require 'libis-tools'

require 'libis/ingester/installer'

require 'highline'
@hl = HighLine.new

@options = {}

def option_menu(title, items)
  return false if items.empty?
  if (name = @options["#{title.downcase}_name".to_sym])
    item = items.find_by(name: name)
    if item
      @options[title.downcase.to_sym] = item
      return
    end
  end
  @hl.choose do |menu|
    menu.prompt = "#{title} number: "
    menu.header = "\n#{title}\n#{'_' * title.size}"
    menu.select_by = :index
    items.each do |i|
      menu.choice("#{i.name} (id: #{i.id})") { @options[title.downcase.to_sym] = i }
    end
    menu.choice('--EXIT--') { @options[title.downcase.to_sym] = nil }
  end
  true
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
  opts.on('-d', '--delete', 'Delete all runs') do |v|
    @options[:delete] = v
  end

  opts.on('-r', '--reset', 'Reset the complete database') do |v|
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

  unless option_menu('User', Libis::Ingester::User.all)
    puts 'ERROR: No user defined.'
    exit 1
  end

  exit 1 unless @options[:user]

  loop do
    @options[:password] = @hl.ask('Password: ') { |q| q.echo = '.' } unless @options[:password]
    break if @options[:user].authenticate(@options[:password])
    @options[:password] = nil
  end
end

def get_org
  get_user
  exit 1 unless @options[:user]

  # noinspection RubyResolve
  unless option_menu('Organization', @options[:user].organizations)
    puts 'ERROR: No organization defined.'
    exit 1
  end
end

def get_job
  get_org unless @options[:organization]
  exit 1 unless @options[:organization]

  # noinspection RubyResolve
  unless option_menu('Job', @options[:organization].jobs)
    puts "ERROR: No jobs found for #{@options[:organization].name}"
    exit 1
  end
end

def get_run
  get_job unless @options[:job]
  exit 1 unless @options[:job]

  # noinspection RubyResolve
  unless option_menu('Run', @options[:job].runs)
    puts "ERROR: No runs found for #{@options[:job].name}"
    exit 1
  end
end

::Libis::Ingester.configure do |cfg|
  cfg.logger = ::Logger.new(STDOUT)
  cfg.set_log_formatter
  cfg.logger.level = Logger::DEBUG
end

