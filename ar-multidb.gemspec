# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'multidb/version'

Gem::Specification.new do |s|
  s.name        = 'ar-multidb'
  s.version     = Multidb::VERSION
  s.authors     = ['Alexander Staubo', 'Edward Rudd']
  s.email       = ['alex@bengler.no', 'urkle@outoforder.cc']
  s.homepage    = ''
  s.summary     = s.description = 'Multidb is an ActiveRecord extension for switching between multiple database connections, such as primary/replica setups.'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.4.0'

  s.add_runtime_dependency 'activerecord', '>= 5.1', '< 6.0'
  s.add_runtime_dependency 'activesupport', '>= 5.1', '< 6.0'

  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rspec', '~> 3.8'
  s.add_development_dependency 'rubocop', '~> 0.88.0'
  s.add_development_dependency 'sqlite3', '~> 1.3'
end
