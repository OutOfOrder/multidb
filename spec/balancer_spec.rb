require_relative 'spec_helper'

describe 'Multidb.balancer' do

  context 'with no configuration' do
    it 'returns nothing' do
      Multidb.balancer.should eq nil
    end
  end

  context 'with configuration' do
    before do
      ActiveRecord::Base.establish_connection(configuration_with_slaves)
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
  end

  describe '#use' do
    context 'with no configuration' do
      it 'raises exception' do
        -> {
          Multidb.use(:something) do
          end
        }.should raise_error(ArgumentError)
      end
    end

    context 'with configuration' do
      before do
        ActiveRecord::Base.establish_connection(configuration_with_slaves)
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

      it 'returns slave connection' do
        Multidb.use(:slave1) do
          conn = ActiveRecord::Base.connection
          conn.should eq Multidb.balancer.current_connection
          list = conn.execute('pragma database_list')
          list.length.should eq 1
          File.basename(list[0]['file']).should eq 'test-slave1.sqlite'
        end
      end

      it 'returns supports nested slave connection' do
        Multidb.use(:slave1) do
          Multidb.use(:slave2) do
            conn = ActiveRecord::Base.connection
            conn.should eq Multidb.balancer.current_connection
            list = conn.execute('pragma database_list')
            list.length.should eq 1
            File.basename(list[0]['file']).should eq 'test-slave2.sqlite'
          end
        end
      end

      it 'returns preserves state when nesting' do
        Multidb.use(:slave1) do
          Multidb.use(:slave2) do
            conn = ActiveRecord::Base.connection
            conn.should eq Multidb.balancer.current_connection
            list = conn.execute('pragma database_list')
            list.length.should eq 1
            File.basename(list[0]['file']).should eq 'test-slave2.sqlite'
          end

          conn = ActiveRecord::Base.connection
          conn.should eq Multidb.balancer.current_connection
          list = conn.execute('pragma database_list')
          list.length.should eq 1
          File.basename(list[0]['file']).should eq 'test-slave1.sqlite'
        end
      end

      it 'returns random candidate' do
        names = []
        100.times do
          Multidb.use(:slave3) do
            list = ActiveRecord::Base.connection.execute('pragma database_list')
            list.length.should eq 1
            names.push(File.basename(list[0]['file']))
          end
        end
        names.sort.uniq.should eq [
          'test-slave3-1.sqlite',
          'test-slave3-2.sqlite'
        ]
      end
    end
  end

end