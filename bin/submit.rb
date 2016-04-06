#!/usr/bin/env ruby
require_relative 'include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  job_opts(opts)

end.parse!

get_initializer
exit unless get_job

Libis::Ingester::JobWorker.perform_async(@options[:job].id)
puts "Job #{@options[:job].name} submitted ..."
