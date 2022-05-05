# frozen_string_literal: true

source 'http://rubygems.org'

# Specify your gem's dependencies in ar-multidb.gemspec
gemspec

local_gemfile = File.expand_path('Gemfile.local', __dir__)
eval(File.read(local_gemfile), binding, local_gemfile) if File.exist?(local_gemfile) # rubocop:disable Security/Eval
