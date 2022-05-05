# frozen_string_literal: true

module Multidb
  class Configuration
    def initialize(default_adapter, configuration_hash)
      @default_handler = ActiveRecord::Base.connection_handler
      @default_adapter = default_adapter
      @raw_configuration = configuration_hash
    end

    attr_reader :default_handler, :default_adapter, :raw_configuration
  end
end
