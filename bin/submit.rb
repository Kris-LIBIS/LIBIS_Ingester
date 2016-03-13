#!/usr/bin/env ruby
require_relative 'include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  job_opts(opts)

end.parse!

get_installer
get_job

require 'sidekiq'
Sidekiq.configure_client do |config|
  # noinspection RubyResolve
  config.redis = {url: @installer.config.sidekiq.redis_url}
end

Libis::Ingester::JobWorker.perform_async(@options[:job].id)
puts "Job #{@options[:job].name} submitted ..."
