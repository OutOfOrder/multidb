module Multidb
  module LogSubscriber
    extend ActiveSupport::Concern

    included do
      def debug_with_multidb(msg)
        if name = Multidb.balancer.current_connection_name
          db = color("[DB: #{name}]", ActiveSupport::LogSubscriber::GREEN, true)
          debug_without_multidb(db + msg)
        else
          debug_without_multidb(msg)
        end
      end
      alias_method_chain :debug, :multidb
    end
  end
end

ActiveRecord::LogSubscriber.send(:include, Multidb::LogSubscriber)
