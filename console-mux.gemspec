Gem::Specification.new do |s|
  s.name        = "console-mux"
  s.version     = File.read('VERSION')
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Patrick Mahoney"]
  s.email       = ["pat@polycrystal.org"]
  s.description = "Multiplex several commands on one console"
  s.summary     = "Multiplex several commands on one console"

  s.files        = Dir.glob(%w[VERSION lib/**/*.rb lib/**/*.sh bin/**/*])
  s.executables = ['console-mux']

  s.add_dependency 'eventmachine' #, "~> 1.0.0.beta.4" beta includes EM::Iterator
  s.add_dependency 'log4r'
  s.add_dependency 'ripl-readline-em', '~> 0.2.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'version', '~> 1'
end
