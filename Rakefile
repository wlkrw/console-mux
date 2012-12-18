require 'rake'
require 'rake/testtask'
require 'rake/version_task'
require 'rubygems/package_task'

def gemspec
  @gemspec ||= eval(File.read('console-mux.gemspec'), binding, 'console-mux.gemspec')
end

Rake::TestTask.new(:test) do |t|
  t.pattern = 'test/**/*_test.rb'
  t.libs.push 'test'
end

Rake::VersionTask.new

Gem::PackageTask.new(gemspec) do |p|
  p.gem_spec = gemspec
end
