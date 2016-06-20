#!/usr/bin/env ruby
require_relative '../lib/libis/ingester/console/process_lib'

get_sidekiq
restart_all_processes
