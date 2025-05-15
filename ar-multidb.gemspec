# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'multidb/version'

Gem::Specification.new do |s|
  s.name        = 'ar-multidb'
  s.version     = Multidb::VERSION
  s.authors     = ['Alexander Staubo', 'Edward Rudd']
  s.email       = %w[alex@bengler.no urkle@outoforder.cc]
  s.homepage    = 'https://github.com/OutOfOrder/multidb'
  s.summary     = s.description = 'Multidb is an ActiveRecord extension for switching between multiple database connections, such as primary/replica setups.'
  s.license     = 'MIT'
  s.metadata['rubygems_mfa_required'] = 'true'
  s.metadata['changelog_uri'] = 'https://github.com/OutOfOrder/multidb/blob/master/CHANGELOG.md'
  s.metadata['source_code_uri'] = 'https://github.com/OutOfOrder/multidb'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 3.0.0'

  s.add_runtime_dependency 'activerecord', '>= 7.1', '< 8.1'
  s.add_runtime_dependency 'activesupport', '>= 7.1', '< 8.1'

  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.8'
  s.add_development_dependency 'rubocop', '~> 1.28.0'
  s.add_development_dependency 'rubocop-rspec', '~> 2.10.0'
  s.add_development_dependency 'simplecov', '~> 0.21.2'
  s.add_development_dependency 'simplecov-lcov', '~> 0.8.0'
  s.add_development_dependency 'sqlite3', '~> 2'
end
