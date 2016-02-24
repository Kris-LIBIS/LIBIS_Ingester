#!/usr/bin/env ruby
require_relative 'include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)

end.parse!

get_installer

require 'sidekiq'
Sidekiq.configure_client do |config|
  # noinspection RubyResolve
  config.redis = {url: @installer.config.config.redis_url}
end

require 'sidekiq/api'

Sidekiq::Queue.all.each do |queue|
  queue.each do |job|
    job.delete
  end
end

Sidekiq::Stats.new.reset
