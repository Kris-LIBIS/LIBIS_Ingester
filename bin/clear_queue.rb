#!/usr/bin/env ruby
require_relative 'include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)

end.parse!

get_installer

require_relative 'sidekiq.config'
Sidekiq::Queue.all.each do |queue|
  queue.each do |job|
    job.delete
  end
end

Sidekiq::Stats.new.reset
