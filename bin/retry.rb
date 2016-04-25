#!/usr/bin/env ruby
require_relative '../lib/libis/ingester/console/include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  run_opts(opts)

end.parse!

get_initializer

exit unless select_run

Libis::Ingester::RunWorker.perform_async(@options[:run].id.to_s, action: :retry)
puts "Retrying Run #{@options[:run].name} ..."
