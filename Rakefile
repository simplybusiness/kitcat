require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'bundler/audit/task'

RSpec::Core::RakeTask.new :spec
RuboCop::RakeTask.new :rubocop
Bundler::Audit::Task.new

task default: [:spec, :rubocop, 'bundle:audit']
