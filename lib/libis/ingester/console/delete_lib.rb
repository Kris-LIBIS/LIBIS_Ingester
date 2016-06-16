#!/usr/bin/env ruby
require_relative 'include'

def delete_menu
  loop do
      break unless select_organization
      loop do
        break unless select_job
        loop do
          @options[:job].reload_relations
          break unless select_run
          delete_run(@options[:run])
          @options[:job].save!
          @options[:run] = nil
        end
        @options[:job] = nil
      end
      @options[:organization] = nil
  end
end

def delete_run(item)
  item.destroy! if @hl.agree("This will destroy all evidence of run #{item.name}. OK?", false)
end

def delete_all_finshed_runs
  ::Libis::Ingester::Run.each do |run|
    next unless run.check_status(:DONE)
    puts '  ' + run.name
    run.destroy!
  end if @hl.agree('This will delete all finished runs. OK?', false)
end

def delete_all_failed_runs
  ::Libis::Ingester::Run.each do |run|
    next unless run.check_status(:FAILED)
    puts '  ' + run.name
    run.destroy!
  end if @hl.agree('This will delete all failed runs. OK?', false)
end

def reset_database
  if @hl.agree('This will reset the complete database to its initial state. OK?', false)
    puts 'Clearing database ...'
    @initializer.database.clear
  end

  puts 'Seeding database ...'
  @initializer.seed_database

  puts 'Done.'
end
