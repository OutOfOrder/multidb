# frozen_string_literal: true

require 'active_record/base'

module Multidb
  module Connection
    def establish_connection(spec = nil)
      super(spec)
      Multidb.init(connection_pool.spec.config)
    end

    def connection
      Multidb.balancer.current_connection
    rescue Multidb::NotInitializedError
      super
    end
  end

  module ModelExtensions
    extend ActiveSupport::Concern

    included do
      class << self
        prepend Multidb::Connection
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Multidb::ModelExtensions
end
