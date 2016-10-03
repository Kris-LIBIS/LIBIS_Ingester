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

def delete_run(item, quiet = false)
  puts "Deleting #{item.name} ..." if quiet
  item.destroy! if quiet || @hl.agree("This will destroy all evidence of run #{item.name}. OK?", false)
end

def delete_item(item, quiet = false)
  item.destroy! if quiet || @hl.agree(
      "This will delete the #{item.class.to_s.split('::').last.downcase} '#{item.name}' from " +
          "#{item.parent.class.to_s.split('::').last.downcase} '#{item.parent.name}'. OK?", false
  )
end

def delete_all_finshed_runs(job = nil)
  quiet = false
  # noinspection RubyResolve
  (job&.runs || ::Libis::Ingester::Run).no_timeout.each do |run|
    next unless run.check_status(:DONE)
    if quiet
      puts "Deleting #{run.name} ..."
    else
      q = @hl.ask("Deleting #{run.name} ... OK ? [Yes/No/All/Quit] ") { |a| a.character = false, a.validate = /[ynaq]/i }.downcase
      next if q == 'n'
      return if q == 'q'
      quiet = true if q == 'a'
    end
    run.destroy!
  end
end

def delete_all_failed_runs(job = nil)
  quiet = false
  # noinspection RubyResolve
  (job&.runs || ::Libis::Ingester::Run).no_timeout.each do |run|
    next unless run.check_status(:FAILED)
    if quiet
      puts "Deleting #{run.name} ..."
    else
      q = @hl.ask("Deleting #{run.name} ... OK ? [Yes/No/All/Quit] ") { |a| a.character = false, a.validate = /[ynaq]/i }.downcase
      next if q == 'n'
      return if q == 'q'
      quiet = true if q == 'a'
    end
    run.destroy!
  end
end

def delete_all_runs(job = nil)
  quiet = false
  # noinspection RubyResolve
  (job&.runs || ::Libis::Ingester::Run).no_timeout.each do |run|
    if quiet
      puts "Deleting #{run.name} ..."
    else
      q = @hl.ask("Deleting #{run.name} ... OK ? [Yes/No/All/Quit] ") { |a| a.character = false, a.validate = /[ynaq]/i }.downcase
      next if q == 'n'
      return if q == 'q'
      quiet = true if q == 'a'
    end
    run.destroy!
  end
end

def delete_orphan_items
  quiet = false
  (::Libis::Ingester::Item).no_timeout.each do |item|
    next if item.is_a? Libis::Ingester::Run
    next if item.parent
    if quiet
      puts "Deleting #{item.name} ..."
    else
      q = @hl.ask("Deleting #{item.name} ... OK ? [Yes/No/All/Quit] ") { |a| a.character = false, a.validate = /[ynaq]/i }.downcase
      next if q == 'n'
      return if q == 'q'
      quiet = true if q == 'a'
    end
    item.destroy!
  end
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
