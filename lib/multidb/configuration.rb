module Multidb

  mattr_reader :configuration

  class << self
    delegate :use, :get, :disconnect!, to: :balancer
  end

  def self.balancer
    @balancer ||= create_balancer
  end

  def self.reset!
    @balancer, @configuration = nil, nil
  end

  class Configuration
    def initialize(default_adapter, configuration_hash)
      @default_pool = ActiveRecord::Base.connection_pool
      @default_adapter = default_adapter
      @raw_configuration = configuration_hash
    end

    attr_reader :default_pool
    attr_reader :default_adapter
    attr_reader :raw_configuration
  end

  private

    def self.create_balancer
      unless @configuration
        begin
          connection_pool = ActiveRecord::Base.connection_pool
        rescue ActiveRecord::ConnectionNotEstablished
          # Ignore
        else
          connection = connection_pool.connection

          # FIXME: This is hacky, but apparently the only way to get at
          #   the internal configuration hash.
          activerecord_config = connection.instance_variable_get(:@config).dup.with_indifferent_access

          default_adapter, configuration_hash = activerecord_config, activerecord_config.delete(:multidb)

          @configuration = Configuration.new(default_adapter, configuration_hash || {})
        end
      end
      if @configuration
        Balancer.new(@configuration)
      end
    end

end