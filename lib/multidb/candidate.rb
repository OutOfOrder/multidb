# frozen_string_literal: true

module Multidb
  class Candidate
    SPEC_NAME = 'ActiveRecord::Base'

    def initialize(name, target)
      @name = name

      case target
      when Hash
        target = target.merge(name: 'primary')

        @connection_handler = ActiveRecord::ConnectionAdapters::ConnectionHandler.new
        @connection_handler.establish_connection(target)
      when ActiveRecord::ConnectionAdapters::ConnectionHandler
        @connection_handler = target
      else
        raise ArgumentError, 'Connection handler not passed to target'
      end
    end

    def connection(&block)
      if block_given?
        @connection_handler.retrieve_connection_pool(SPEC_NAME).with_connection(&block)
      else
        @connection_handler.retrieve_connection(SPEC_NAME)
      end
    end

    def disconnect!
      @connection_handler.clear_all_connections!
    end

    attr_reader :name
  end
end
