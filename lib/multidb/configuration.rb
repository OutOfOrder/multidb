module Multidb
  
  class << self
    
    def configure!
      connection_pool = ActiveRecord::Base.connection_pool
      if connection_pool
        connection = connection_pool.connection
        activerecord_config = connection.instance_variable_get(:@config).dup.with_indifferent_access
        default_adapter, configuration_hash = activerecord_config, activerecord_config.delete(:multidb)
        configuration_hash ||= {}
        @configuration = Configuration.new(default_adapter, configuration_hash)
      end
    end

    attr_reader :configuration
          
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
  
end
