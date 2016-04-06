#!/usr/bin/env ruby
require_relative 'include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  run_opts(opts)

end.parse!

get_initializer

exit unless get_run

Libis::Ingester::RunWorker.perform_async(@options[:run].id, action: :retry)
puts "Retrying Run #{@options[:run].name} ..."
