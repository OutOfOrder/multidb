module Multidb
  
  class Candidate
    def initialize(target)
      if target.is_a?(Hash)
        adapter = target[:adapter]
        begin
          require "active_record/connection_adapters/#{adapter}_adapter"
        rescue LoadError
          raise "Please install the #{adapter} adapter: `gem install activerecord-#{adapter}-adapter` (#{$!})"
        end
        @connection_pool = ActiveRecord::ConnectionAdapters::ConnectionPool.new(
          ActiveRecord::Base::ConnectionSpecification.new(target, "#{adapter}_connection"))
      else
        @connection_pool = target
      end
    end
    
    def connection(&block)
      if block_given?
        @connection_pool.with_connection(&block)
      else
        @connection_pool.connection
      end
    end

    attr_reader :connection_pool
  end
  
  class Balancer
    
    def initialize(configuration)
      @candidates = {}.with_indifferent_access
      @configuration = configuration
      if @configuration
        (@configuration.raw_configuration[:databases] || {}).each_pair do |name, config|
          configs = config.is_a?(Array) ? config : [config]
          configs.each do |config|          
            candidate = Candidate.new(@configuration.default_adapter.merge(config))
            @candidates[name] ||= []
            @candidates[name].push(candidate)
          end
        end
        if @configuration.raw_configuration.include?(:fallback)
          @fallback = @configuration.raw_configuration[:fallback]
        elsif defined?(Rails)
          @fallback = %w(development test).include?(Rails.env)
        else
          @fallback = false
        end
        @default_candidate = Candidate.new(@configuration.default_pool)
        unless @candidates.include?(:default)
          @candidates[:default] = [@default_candidate]
        end
      end
    end

    def disconnect!
      @candidates.values.each do |candidate|
        candidate.connection_pool.disconnect!
      end
    end

    def get(name, &block)
      candidates = @candidates[name]
      candidates ||= @fallback ? @candidates[:default] : []
      raise ArgumentError, "No such database connection '#{name}'" if candidates.empty?
      candidate = candidates.respond_to?(:sample) ? 
        candidates.sample : candidates[rand(candidates.length)]
      block_given? ? yield(candidate) : candidate
    end
    
    def use(name, &block)
      result = nil
      get(name) do |candidate|
        if block_given?
          candidate.connection do |connection|
            previous_connection, Thread.current[:multidb_connection] = 
              Thread.current[:multidb_connection], connection
            begin
              result = yield
            ensure
              Thread.current[:multidb_connection] = previous_connection
            end
            result
          end
        else
          result = Thread.current[:multidb_connection] = candidate.connection
        end
      end
      result
    end
    
    def current_connection
      Thread.current[:multidb_connection] || @default_candidate.connection
    end
    
    class << self
      def use(name, &block)
        Multidb.balancer.use(name, &block)
      end
      
      def current_connection
        Multidb.balancer.current_connection
      end

      def disconnect!
        Multidb.balancer.disconnect!
      end
    end
    
  end
  
end
