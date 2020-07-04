# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "multidb/version"

Gem::Specification.new do |s|
  s.name        = "ar-multidb"
  s.version     = Multidb::VERSION
  s.authors     = ["Alexander Staubo"]
  s.email       = ["alex@bengler.no"]
  s.homepage    = ""
  s.summary     = s.description = %q{Multidb is an ActiveRecord extension for switching between multiple database connections, such as primary/replica setups.}

  s.rubyforge_project = "ar-multidb"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'activesupport', '>= 5.1', '<= 6.0'
  s.add_runtime_dependency 'activerecord', '>= 5.1', '<= 6.0'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rake'
end
