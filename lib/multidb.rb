# frozen_string_literal: true

require 'active_record'

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/module/aliasing'

require_relative 'multidb/configuration'
require_relative 'multidb/model_extensions'
require_relative 'multidb/log_subscriber'
require_relative 'multidb/candidate'
require_relative 'multidb/balancer'
require_relative 'multidb/version'

module Multidb
  # Error raised when the configuration has not been initialized
  class NotInitializedError < StandardError; end

  class << self
    delegate :use, :get, :disconnect!, to: :balancer
  end

  def self.init(config)
    activerecord_config = config.dup.with_indifferent_access
    default_adapter     = activerecord_config
    configuration_hash  = activerecord_config.delete(:multidb)

    @balancer = Balancer.new(Configuration.new(default_adapter, configuration_hash || {}))
  end

  def self.balancer
    @balancer || raise(NotInitializedError, 'Balancer not initialized. You need to run Multidb.init first')
  end

  def self.reset!
    @balancer = nil
    Thread.current[:multidb] = nil
  end
end
