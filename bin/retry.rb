#!/usr/bin/env ruby
require_relative '../lib/libis/ingester/console/include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  run_opts(opts)

end.parse!

get_initializer
loop do
  @options[:run] = nil
  exit unless select_run

  queue = select_defined_queue
  next unless queue

  Sidekiq::Client.push(
      'class' => 'Libis::Ingester::RunWorker',
      'queue' => queue.name,
      'retry' => false,
      'args' => { action: :retry }
  )

  puts "Retrying Run #{@options[:run].name} ..."
end

