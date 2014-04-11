require 'bundler/gem_tasks'
require 'rake/extensiontask'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)
Rake::ExtensionTask.new('Parsers') do |ext|
  ext.ext_dir = 'ext/parser'
  ext.lib_dir = 'lib/redxml/server/xquery'
end

task :default => :spec
