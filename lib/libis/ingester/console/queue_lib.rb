#!/usr/bin/env ruby
require_relative 'include'

def queue_menu
  loop do
    break unless (queue = select_defined_queue(with_create: true, with_delete: true))
    loop do
      break unless (worker = select_worker(queue))
      worker.delete if @hl.agree("About to delete '#{worker_name(worker)}' from the queue. OK?", false)
    end
  end
end