# frozen_string_literal: true

module Multidb
  class Balancer
    attr_accessor :fallback

    def initialize(configuration)
      @candidates = {}.with_indifferent_access
      @default_configuration = configuration

      return unless @default_configuration

      append(@default_configuration.raw_configuration[:databases] || {})

      @fallback = if @default_configuration.raw_configuration.include?(:fallback)
                    @default_configuration.raw_configuration[:fallback]
                  elsif defined?(Rails)
                    %w[development test].include?(Rails.env)
                  else
                    false
                  end

      @default_candidate = Candidate.new('default', @default_configuration.default_handler)

      @candidates[:default] = [@default_candidate] unless @candidates.include?(:default)
    end

    def append(databases)
      databases.with_indifferent_access.each_pair do |name, config|
        configs = config.is_a?(Array) ? config : [config]
        configs.each do |cfg|
          if cfg['alias']
            @candidates[name] = @candidates[cfg['alias']]
            next
          end

          candidate = Candidate.new(name, @default_configuration.default_adapter.merge(cfg))
          @candidates[name] ||= []
          @candidates[name].push(candidate)
        end
      end
    end

    def disconnect!
      @candidates.values.flatten.each(&:disconnect!)
    end

    def get(name, &_block)
      candidates = @candidates[name]
      candidates ||= @fallback ? @candidates[:default] : []

      raise ArgumentError, "No such database connection '#{name}'" if candidates.empty?

      candidate = candidates.sample

      block_given? ? yield(candidate) : candidate
    end

    def use(name, &_block)
      result = nil
      get(name) do |candidate|
        if block_given?
          candidate.connection do |connection|
            previous_configuration = Thread.current[:multidb]
            Thread.current[:multidb] = {
              connection: connection,
              connection_name: name
            }
            begin
              result = yield
              result = result.to_a if result.is_a?(ActiveRecord::Relation)
            ensure
              Thread.current[:multidb] = previous_configuration
            end
            result
          end
        else
          Thread.current[:multidb] = {
            connection: candidate.connection,
            connection_name: name
          }
          result = candidate.connection
        end
      end
      result
    end

    def current_connection
      if Thread.current[:multidb]
        Thread.current[:multidb][:connection]
      else
        @default_candidate.connection
      end
    end

    def current_connection_name
      if Thread.current[:multidb]
        Thread.current[:multidb][:connection_name]
      else
        :default
      end
    end

    class << self
      def use(name, &block)
        Multidb.balancer.use(name, &block)
      end

      def current_connection
        Multidb.balancer.current_connection
      end

      def current_connection_name
        Multidb.balancer.current_connection_name
      end

      def disconnect!
        Multidb.balancer.disconnect!
      end
    end
  end
end
