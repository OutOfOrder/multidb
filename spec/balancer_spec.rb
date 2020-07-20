require_relative 'spec_helper'

describe 'Multidb.balancer' do

  context 'with no configuration' do
    it 'raises exception' do
      -> { Multidb.balancer }.should raise_error(Multidb::NotInitializedError)
    end
  end

  context 'with configuration' do
    before do
      ActiveRecord::Base.establish_connection(configuration_with_replicas)
    end

    it 'returns balancer' do
      Multidb.balancer.should_not eq nil
    end

    it 'returns main connection by default' do
      conn = ActiveRecord::Base.connection

      list = conn.execute('pragma database_list')
      list.length.should eq 1
      File.basename(list[0]['file']).should eq 'test.sqlite'

      Multidb.balancer.current_connection.should eq conn
    end

    it 'returns default connection name for default connection' do
      conn = ActiveRecord::Base.connection

      Multidb.balancer.current_connection_name.should eq :default
    end

    context 'with additional configurations' do
      before do
        additional_configuration = {replica4: { database: 'spec/test-replica4.sqlite' }}
        Multidb.balancer.append(additional_configuration)
      end

      it 'makes the new database available' do
        Multidb.use(:replica4) do
          conn = ActiveRecord::Base.connection
          conn.should eq Multidb.balancer.current_connection
          list = conn.execute('pragma database_list')
          list.length.should eq 1
          File.basename(list[0]['file']).should eq 'test-replica4.sqlite'
        end
      end

      it 'returns the connection name' do
        Multidb.use(:replica4) do
          Multidb.balancer.current_connection_name.should eq :replica4
        end
      end
    end
  end

  describe '#use' do
    context 'with configuration' do
      before do
        ActiveRecord::Base.establish_connection(configuration_with_replicas)
      end

      context 'undefined connection' do
        it 'raises exception' do
          -> {
            Multidb.use(:something) do
            end
          }.should raise_error(ArgumentError)
        end
      end

      it 'returns default connection on :default' do
        conn = ActiveRecord::Base.connection
        Multidb.use(:default) do
          conn2 = ActiveRecord::Base.connection
          conn2.should eq Multidb.balancer.current_connection

          list = conn2.execute('pragma database_list')
          list.length.should eq 1
          File.basename(list[0]['file']).should eq 'test.sqlite'
        end
      end

      it 'returns replica connection' do
        Multidb.use(:replica1) do
          conn = ActiveRecord::Base.connection
          conn.should eq Multidb.balancer.current_connection
          list = conn.execute('pragma database_list')
          list.length.should eq 1
          File.basename(list[0]['file']).should eq 'test-replica1.sqlite'
        end
      end

      it 'returns results instead of relation' do
        class FooBar < ActiveRecord::Base; end
        res = Multidb.use(:replica1) do
          ActiveRecord::Migration.verbose = false
          ActiveRecord::Schema.define(version: 1) { create_table :foo_bars }
          FooBar.where(id: 42)
        end
        res.should eq []
      end

      it 'returns supports nested replica connection' do
        Multidb.use(:replica1) do
          Multidb.use(:replica2) do
            conn = ActiveRecord::Base.connection
            conn.should eq Multidb.balancer.current_connection
            list = conn.execute('pragma database_list')
            list.length.should eq 1
            File.basename(list[0]['file']).should eq 'test-replica2.sqlite'
          end
        end
      end

      it 'returns preserves state when nesting' do
        Multidb.use(:replica1) do
          Multidb.use(:replica2) do
            conn = ActiveRecord::Base.connection
            conn.should eq Multidb.balancer.current_connection
            list = conn.execute('pragma database_list')
            list.length.should eq 1
            File.basename(list[0]['file']).should eq 'test-replica2.sqlite'
          end

          conn = ActiveRecord::Base.connection
          conn.should eq Multidb.balancer.current_connection
          list = conn.execute('pragma database_list')
          list.length.should eq 1
          File.basename(list[0]['file']).should eq 'test-replica1.sqlite'
        end
      end

      it 'returns the parent connection for aliases' do
        Multidb.use(:replica1).should_not eq Multidb.use(:replica_alias)
        Multidb.use(:replica2).should eq Multidb.use(:replica_alias)
      end

      it 'returns random candidate' do
        names = []
        100.times do
          Multidb.use(:replica3) do
            list = ActiveRecord::Base.connection.execute('pragma database_list')
            list.length.should eq 1
            names.push(File.basename(list[0]['file']))
          end
        end
        names.sort.uniq.should eq [
          'test-replica3-1.sqlite',
          'test-replica3-2.sqlite'
        ]
      end
    end
  end

end
