#!/usr/bin/env ruby
require_relative '../lib/libis/ingester/console/status_lib'
require_relative '../lib/libis/ingester/console/submit_lib'
require_relative '../lib/libis/ingester/console/retry_lib'
require_relative '../lib/libis/ingester/console/setup_db_lib'
require_relative '../lib/libis/ingester/console/queue_lib'
require_relative '../lib/libis/ingester/console/process_lib'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)

end.parse!

get_initializer

loop do
  item = selection_menu(
      'Ingester menu',
      [:status, :submit, :retry, :setup_db, :queue, :process]
  )
  break unless item
  send("#{item}_menu") if item.is_a?(Symbol)
end
