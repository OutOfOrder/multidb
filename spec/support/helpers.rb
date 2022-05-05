# frozen_string_literal: true

module Helpers
  def configuration_with_replicas
    YAML.safe_load(<<~YAML)
      adapter: sqlite3
      database: spec/test.sqlite
      encoding: utf-8
      multidb:
        databases:
          replica1:
            database: spec/test-replica1.sqlite
          replica2:
            database: spec/test-replica2.sqlite
          replica3:
            - database: spec/test-replica3-1.sqlite
            - database: spec/test-replica3-2.sqlite
          replica_alias:
            alias: replica2
    YAML
  end
end

RSpec.configure do |config|
  config.include Helpers
end
