module Multidb
  
  class << self
    
    def configure!
      activerecord_config = ActiveRecord::Base.connection_pool.connection.instance_variable_get(:@config).dup.with_indifferent_access
      default_adapter, configuration_hash = activerecord_config, activerecord_config.delete(:multidb)
      configuration_hash ||= {}
      @configuration = Configuration.new(default_adapter, configuration_hash)
    end

    attr_reader :configuration
          
  end
  
  class Configuration
    def initialize(default_adapter, configuration_hash)
      @default_adapter = default_adapter
      @raw_configuration = configuration_hash
    end

    attr_reader :default_adapter
    attr_reader :raw_configuration
  end
  
end
