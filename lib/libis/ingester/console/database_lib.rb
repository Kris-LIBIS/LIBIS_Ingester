#!/usr/bin/env ruby
require_relative 'include'
require_relative 'delete_lib'

def database_menu
  loop do
    item = selection_menu(
        'Database menu',
        [:seed, :delete_orphans, :delete_finished_runs]
    )
    break unless item
    send("db_#{item}") if item.is_a?(Symbol)
    @options.clear
  end
end

def db_seed
  puts 'Seeding database ...'
  @initializer.seed_database
  puts 'Done.'
end

def db_delete_orphans
  delete_orphan_items
end

def db_delete_finished_runs
  delete_all_finshed_runs
end
