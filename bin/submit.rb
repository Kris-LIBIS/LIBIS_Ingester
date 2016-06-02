#!/usr/bin/env ruby
require_relative '../lib/libis/ingester/console/include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  job_opts(opts)

end.parse!

get_initializer
loop do
  @options[:job] = nil
  exit unless select_job
  queue = select_defined_queue
  next unless queue

  job = @options[:job]
  options = [job.id.to_s]

  options[1] = select_options(job)

  bulk = select_bulk_option(options[1])

  if bulk
    key = bulk[:key]
    next unless @hl.agree("Ready to submit #{bulk[:values].count} jobs for #{@options[:job].name}. OK?", false)

    bulk[:values].each do |value|
      options[1][key] = value
      Sidekiq::Client.push(
          'class' => 'Libis::Ingester::JobWorker',
          'queue' => queue.name,
          'retry' => false,
          'args' => options
      )
      sleep(0.5)
      puts "Job #{@options[:job].name} submitted for #{key} = #{value}"
    end
  else
    next unless @hl.agree("Ready to submit job #{@options[:job].name} with #{options[1]}. OK?", false)
    Sidekiq::Client.push(
        'class' => 'Libis::Ingester::JobWorker',
        'queue' => queue.name,
        'retry' => false,
        'args' => options
    )
    puts "Job #{@options[:job].name} submitted with #{options[1]}."
  end
end

