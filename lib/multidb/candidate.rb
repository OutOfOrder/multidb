# frozen_string_literal: true

module Multidb
  class Candidate
    def initialize(name, target)
      @name = name

      case target
      when Hash
        @connection_handler = ActiveRecord::ConnectionAdapters::ConnectionHandler.new
        @connection_handler.establish_connection(target.merge(name: 'primary'))
      when ActiveRecord::ConnectionAdapters::ConnectionHandler
        @connection_handler = target
      else
        raise ArgumentError, 'Connection handler not passed to target'
      end
    end

    def connection(&block)
      if block_given?
        @connection_handler.retrieve_connection_pool('primary').with_connection(&block)
      else
        @connection_handler.retrieve_connection('primary')
      end
    end

    def disconnect!
      @connection_handler.clear_all_connections!
    end

    attr_reader :name
  end
end
