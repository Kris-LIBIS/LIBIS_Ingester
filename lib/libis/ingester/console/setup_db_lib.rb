#!/usr/bin/env ruby
require_relative 'include'

def setup_db_menu
  puts 'Seeding database ...'
  @initializer.seed_database
  puts 'Done.'
end

