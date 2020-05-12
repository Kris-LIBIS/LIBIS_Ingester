#!/usr/bin/env ruby
require_relative 'include'

def queue_menu
  loop do
    break unless (queue = select_defined_queue(with_create: true, with_delete: true))
    loop do
      break unless (worker = select_worker(queue, true))
      if worker.is_a?(Array)
        puts 'Selected:'
        worker.each { |w| puts worker_detail(w) }
        worker.each do |w|
          w.delete
        end if @hl.agree('Delete all selected workers from the queue?', false)
      else
        worker.delete if @hl.agree("About to delete '#{worker_name(worker)}' from the queue. OK?", false)
      end
    end
  end
end