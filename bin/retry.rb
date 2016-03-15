#!/usr/bin/env ruby
require_relative 'include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  run_opts(opts)

end.parse!

get_installer
get_run

require 'sidekiq'
Sidekiq.configure_client do |config|
  # noinspection RubyResolve
  config.redis = {url: @installer.config.sidekiq.redis_url}
end
Libis::Ingester::RunWorker.perform_async(@options[:run].id, action: :retry)
puts "Retrying Run #{@options[:run].name} ..."
