module Multidb
  module LogSubscriberExtension
    def sql(event)
      if Multidb.balancer? && name = Multidb.balancer.current_connection_name
        event.payload[:db_name] = name
      end
      super
    end

    def debug(msg)
      if Multidb.balancer? && name = Multidb.balancer.current_connection_name
        db = color("[DB: #{name}]", ActiveSupport::LogSubscriber::GREEN, true)
        super(db + msg)
      else
        super
      end
    end
  end
end

ActiveRecord::LogSubscriber.prepend(Multidb::LogSubscriberExtension)
