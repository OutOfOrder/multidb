module Multidb
  class << self
    delegate :use, :get, :disconnect!, to: :balancer
  end

  def self.init(config)
    activerecord_config = config.dup.with_indifferent_access
    default_adapter, configuration_hash = activerecord_config, activerecord_config.delete(:multidb)

    @balancer = Balancer.new(Configuration.new(default_adapter, configuration_hash || {}))
  end

  def self.balancer?
    @balancer != nil
  end

  def self.balancer
    if @balancer
      @balancer
    else
      raise NotInitializedError, "Balancer not initialized. You need to run Multidb.init first"
    end
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

    attr_reader :default_handler
    attr_reader :default_adapter
    attr_reader :raw_configuration
  end
end