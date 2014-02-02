module Multidb
  module ModelExtensions

    extend ActiveSupport::Concern

    included do
      class << self
        alias_method_chain :connection, :multidb
      end
    end

    module ClassMethods
      def connection_with_multidb
        if (balancer = Multidb.balancer)
          balancer.current_connection
        else
          connection_without_multidb
        end
      end
    end

  end
end

ActiveRecord::Base.class_eval do
  include Multidb::ModelExtensions
end
