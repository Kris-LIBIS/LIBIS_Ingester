#!/usr/bin/env ruby
require_relative '../lib/libis/ingester/console/include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  job_opts(opts)

end.parse!

get_initializer
loop do
  exit unless select_job
  queue = select_defined_queue
  next unless queue

  job = @options[:job]
  options = [job.id.to_s]

  options[1] = select_options(job)

  Sidekiq::Client.push(
      'class' => 'Libis::Ingester::JobWorker',
      'queue' => queue.name,
      'retry' => false,
      'args' => options
  )

  puts "Job #{@options[:job].name} submitted #{"with options #{options[1].to_s}" if options[1]}..."
  @options[:job] = nil
end

