module Helpers

  def configuration_with_replicas
    return YAML.load(<<-end)
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
      database: spec/test-replica2.sqlite
      alias: replica2
end
  end

end
