module Multidb
  
  class Candidate
    def initialize(config)
      adapter = config[:adapter]
      begin
        require "active_record/connection_adapters/#{adapter}_adapter"
      rescue LoadError
        raise "Please install the #{adapter} adapter: `gem install activerecord-#{adapter}-adapter` (#{$!})"
      end
      @connection_pool = ActiveRecord::ConnectionAdapters::ConnectionPool.new(
        ActiveRecord::Base::ConnectionSpecification.new(config, "#{adapter}_connection"))
    end
    
    def connection
      @connection_pool.connection
    end
  end
  
  class Balancer
    
    def initialize(configuration)
      @candidates = {}.with_indifferent_access
      @configuration = configuration
      @configuration.raw_configuration[:databases].each_pair do |name, config|
        configs = config.is_a?(Array) ? config : [config]
        configs.each do |config|          
          candidate = Candidate.new(@configuration.default_adapter.merge(config))
          @candidates[name] ||= []
          @candidates[name].push(candidate)
        end
      end
      @default_candidate = Candidate.new(@configuration.default_adapter)
      unless @candidates.include?(:default)
        @candidates[:default] = [@default_candidate]
      end
    end
    
    def get(name, &block)
      candidates = @candidates[name] || []
      raise ArgumentError, "No such database connection '#{name}'" if candidates.blank?
      candidate = candidates.respond_to?(:sample) ? 
        candidates.sample : candidates[rand(candidates.length)]
      block_given? ? yield(candidate) : candidate
    end
    
    def use(name, &block)
      result = nil
      get(name) do |candidate|
        connection = candidate.connection
        if block_given?
          previous_connection, Thread.current[:multidb_connection] = 
            Thread.current[:multidb_connection], connection
          begin
            result = yield
          ensure
            Thread.current[:multidb_connection] = previous_connection
          end
          result
        else
          result = Thread.current[:multidb_connection] = connection
        end
      end
      result
    end
    
    def current_connection
      Thread.current[:multidb_connection] ||= @default_candidate.connection
    end
    
    class << self
      def use(name, &block)
        Multidb.balancer.use(name, &block)
      end
      
      def current_connection
        Multidb.balancer.current_connection
      end
    end
    
  end
  
end
