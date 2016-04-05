#!/usr/bin/env ruby
require_relative 'include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  job_opts(opts)

end.parse!

get_installer
exit unless get_job

require_relative 'sidekiq.config'
Libis::Ingester::JobWorker.perform_async(@options[:job].id)
puts "Job #{@options[:job].name} submitted ..."
