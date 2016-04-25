#!/usr/bin/env ruby
require_relative '../lib/libis/ingester/console/include'
get_initializer

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)

end.parse!

loop do
  break unless (queue = select_defined_queue(with_create: true, with_delete: true))
  loop do
    break unless (worker = select_worker(queue))
    worker.delete
  end
end

# Sidekiq::Stats.new.reset
