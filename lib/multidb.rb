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
        @balancer = Balancer.new(@configuration)
      end
    end
    
    attr_reader :balancer

    delegate :use, :get, :to => :balancer

  end
end

Multidb.install!
