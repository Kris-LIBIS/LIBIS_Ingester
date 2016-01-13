#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis-ingester'
require 'libis-workflow'
require 'libis-workflow-mongoid'
require 'libis-format'
require 'libis-services'
require 'libis-tools'

require 'optparse'

def option_menu(title, items)
  if (name = @options["#{title.downcase}_name".to_sym])
    item = items.find_by(name: name)
    if item
      @options[title.downcase.to_sym] = item
      return
    end
  end
  puts title
  puts '_' * title.size
  items
  items.each_with_index { |item, i| puts "#{i}. #{item.name}" }
  item_nr = ask("#{title} number: ", Integer) { |q| q.in = 0...items.size }
  @options[title.downcase.to_sym] = items[item_nr]
end

@options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: submit.rb [options]'

  opts.on('-c', '--config CONFIG', 'Config file') do |v|
    @options[:config] = v
  end

  opts.on('-u', '--user USER', 'User name') do |v|
    @options[:user_name] = v
  end

  opts.on('-p', '--password PASSWORD', 'Password') do |v|
    @options[:password] = v
  end

  opts.on('-o', '--organization NAME', 'Organization name') do |v|
    @options[:organization_name] = v
  end

  opts.on('-j', '--job NAME', 'Job name') do |v|
    @options[:job_name] = v
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

end.parse!

require 'libis/ingester/installer'

installer = ::Libis::Ingester::Installer.new(@options[:config] || 'site.config.yml')
::Libis::Ingester.configure do |cfg|
  cfg.logger = ::Logger.new(STDOUT)
  cfg.set_log_formatter
  cfg.logger.level = Logger::DEBUG
end

require 'sidekiq'

Sidekiq.configure_client do |config|
  # noinspection RubyResolve
  config.redis = {url: installer.config.config.redis_url}
end

require 'highline/import'

option_menu('User', Libis::Ingester::User.all) unless @options[:user]

loop do
  @options[:password] = ask('Password: ') { |q| q.echo = '.' } unless @options[:password]
  break if @options[:user].authenticate(@options[:password])
  @options[:password] = nil
end

# noinspection RubyResolve
option_menu('Organization', @options[:user].organizations)

# noinspection RubyResolve
option_menu('Job', @options[:organization].jobs)

Libis::Ingester::JobWorker.perform_async(@options[:job].id)
puts "Job #{@options[:job].name} submitted ..."
