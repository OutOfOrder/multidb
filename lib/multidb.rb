require 'active_record'

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/module/aliasing'

require_relative 'multidb/configuration'
require_relative 'multidb/model_extensions'
require_relative 'multidb/log_subscriber'
require_relative 'multidb/balancer'
require_relative 'multidb/version'
