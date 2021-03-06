#!/usr/bin/env ruby
require_relative 'include'

def retry_menu
  loop do
    @options[:job] = nil
    break unless select_job
    loop do
      @options[:run] = nil
      break unless select_run

      queue = select_defined_queue
      next unless queue

      Libis::Ingester::RunWorker.push_retry_job(@options[:run].id.to_s, queue.name)

      puts "Retrying Run #{@options[:run].name} ..."
    end
  end
end
