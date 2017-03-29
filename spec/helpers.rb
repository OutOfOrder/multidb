module Helpers

  def configuration_with_slaves
    return YAML.load(<<-end)
adapter: sqlite3
database: spec/test.sqlite
encoding: utf-8
multidb:
  databases:
    slave1:
      database: spec/test-slave1.sqlite
    slave2:
      database: spec/test-slave2.sqlite
    slave3:
      - database: spec/test-slave3-1.sqlite
      - database: spec/test-slave3-2.sqlite
    slave4:
      database: spec/test-slave2.sqlite
      alias: slave2
      
end
  end

end
