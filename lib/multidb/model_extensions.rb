module Multidb
  module ModelExtensions
    
    class << self
      def append_features(base)
        base.extend(ClassMethods)
        base.class_eval do
          include Multidb::ModelExtensions::InstanceMethods
          class << self
            alias_method_chain :connection, :multidb
          end
        end
      end
    end

    module ClassMethods
      def connection_with_multidb
        Multidb.balancer.current_connection
      end
    end

    module InstanceMethods
    end
    
  end
end
