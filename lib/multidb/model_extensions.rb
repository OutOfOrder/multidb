require 'active_record/base'

module Multidb
  module ModelExtensions
    extend ActiveSupport::Concern

    included do
      class << self
        alias_method_chain :establish_connection, :multidb
        alias_method_chain :connection, :multidb
      end
    end

    module ClassMethods
      def establish_connection_with_multidb(spec = ENV["DATABASE_URL"])
        establish_connection_without_multidb(spec)
        Multidb.init(connection_pool.spec.config)
      end

      def connection_with_multidb
        Multidb.balancer.current_connection
      rescue Multidb::NotInitializedError
        connection_without_multidb
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Multidb::ModelExtensions
end
