require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec')

desc 'run tests'
task :default => :spec

require 'libis/ingester'

require 'github_changelog_generator/task'
GitHubChangelogGenerator::RakeTask.new :changelog do |_|
end