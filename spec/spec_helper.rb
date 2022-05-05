# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

ENV['RACK_ENV'] ||= 'test'

require 'rspec'
require 'yaml'
require 'active_record'
require 'fileutils'

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'multidb'

Dir[File.join(__dir__, 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.filter_run_excluding rails: lambda { |v|
    rails_version = Gem::Version.new(ActiveRecord::VERSION::STRING)
    test = Gem::Requirement.new(v)
    !test.satisfied_by?(rails_version)
  }

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before do
    ActiveRecord::Base.clear_all_connections!
    Multidb.reset!
  end

  config.after do
    Multidb.reset!
    Dir.glob(File.expand_path('test*.sqlite', __dir__)).each do |f|
      FileUtils.rm(f)
    end
  end
end
