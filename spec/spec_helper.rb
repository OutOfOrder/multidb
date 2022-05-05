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

require_relative 'helpers'

RSpec.configure do |config|
  config.include Helpers
  config.expect_with(:rspec) { |c| c.syntax = :should }
  config.before :each do
    ActiveRecord::Base.clear_all_connections!
    Multidb.reset!
  end
  config.after :each do
    Dir.glob(File.expand_path('test*.sqlite', __dir__)).each do |f|
      FileUtils.rm(f)
    end
  end
end
