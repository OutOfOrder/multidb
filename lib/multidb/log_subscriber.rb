# frozen_string_literal: true

module Multidb
  module LogSubscriberExtension
    def sql(event)
      name = Multidb.balancer.current_connection_name
      event.payload[:db_name] = name if name
      super
    end

    def debug(msg = nil)
      name = Multidb.balancer.current_connection_name
      if name
        db = color("[DB: #{name}]", ActiveSupport::LogSubscriber::GREEN, bold: true)
        super(db + msg.to_s)
      else
        super
      end
    end
  end
end

ActiveRecord::LogSubscriber.prepend(Multidb::LogSubscriberExtension)
