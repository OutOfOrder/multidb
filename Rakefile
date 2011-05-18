# encoding: utf-8

require 'rubygems'
require 'rake'
require 'rake/rdoctask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = 'ar-multidb'
    gem.summary = gem.description = %Q{Multidb is an ActiveRecord extension for switching between multiple database connections, such as master/slave setups.}
    gem.email = "alex@bengler.no"
    gem.homepage = "http://github.com/alexstaubo/multidb"
    gem.authors = ["Alexander Staubo"]
    gem.has_rdoc = true
    gem.require_paths = ["lib"]
    gem.files = FileList[%W(
      README.markdown
      VERSION
      LICENSE*
      lib/**/*
    )]
    gem.add_dependency 'activesupport', '>= 2.2'
    gem.add_dependency 'activerecord', '>= 2.2'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  $stderr << "Warning: Gem-building tasks are not included as Jeweler (or a dependency) not available. Install it with: `gem install jeweler`.\n"
end

Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ruby-hdfs #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
