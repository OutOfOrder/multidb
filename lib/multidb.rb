require 'active_record'
require 'active_support/core_ext/module/delegation'

require 'multidb/configuration'
require 'multidb/model_extensions'
require 'multidb/balancer'

module Multidb
  class << self
    
    def install!
      configure!
      if @configuration and not @configuration.raw_configuration[:databases].blank?
        ActiveRecord::Base.class_eval do
          include Multidb::ModelExtensions
        end
      end
      @balancer = Balancer.new(@configuration)
    end

    def reconfigure!
      @balancer = Balancer.new(@configuration)
    end
    
    attr_reader :balancer

    delegate :use, :get, :to => :balancer

  end
end

if defined?(Rails) && Rails::VERSION::MAJOR >= 3
  require 'multidb/railtie'
else
  Multidb.install!
end
