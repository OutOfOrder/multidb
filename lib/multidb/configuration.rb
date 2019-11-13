# frozen_string_literal: true

module Multidb
  class << self
    delegate :use, :get, :disconnect!, to: :balancer
  end

  def self.init(config)
    activerecord_config = config.dup.with_indifferent_access
    default_adapter = activerecord_config
    configuration_hash = activerecord_config.delete(:multidb)

    @balancer = Balancer.new(Configuration.new(default_adapter, configuration_hash || {}))
  end

  def self.balancer
    @balancer || raise(NotInitializedError, 'Balancer not initialized. You need to run Multidb.init first')
  end

  def self.reset!
    @balancer = nil
  end

  class NotInitializedError < StandardError; end

  class Configuration
    def initialize(default_adapter, configuration_hash)
      @default_handler = ActiveRecord::Base.connection_handler
      @default_adapter = default_adapter
      @raw_configuration = configuration_hash
    end

    attr_reader :default_handler, :default_adapter, :raw_configuration
  end
end
