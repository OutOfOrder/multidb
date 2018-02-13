source "http://rubygems.org"

# Specify your gem's dependencies in ar-multidb.gemspec
gemspec

local_gemfile = "Gemfile.local"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Security/Eval
end

group :test do
  # For travis-ci.org
  gem "rake"
end
