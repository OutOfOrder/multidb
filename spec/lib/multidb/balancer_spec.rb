# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Multidb::Balancer do
  let(:config) { configuration_with_replicas }
  let(:configuration) {
    c = config.with_indifferent_access
    Multidb::Configuration.new(c.except(:multidb), c[:multidb] || {})
  }
  let(:balancer) { global_config ? Multidb.balancer : described_class.new(configuration) }
  let(:global_config) { false }

  before do
    ActiveRecord::Base.establish_connection(config) if global_config
  end

  describe '#initialize' do
    subject { balancer }

    context 'when configuration has no multidb config' do
      let(:config) { configuration_with_replicas.except('multidb') }

      it 'sets @candidates to have only default set of candidates' do
        expect(subject.instance_variable_get(:@candidates).keys).to contain_exactly('default')
      end

      it 'sets @default_candidate to be the fist candidate for the default @candidates' do
        candidates = subject.instance_variable_get(:@candidates)

        expect(subject.instance_variable_get(:@default_candidate)).to eq(candidates['default'].first)
      end

      it 'sets @default_configuration to be the configuration' do
        expect(subject.instance_variable_get(:@default_configuration)).to eq(configuration)
      end

      it 'sets fallback to false' do
        expect(subject.fallback).to eq(false)
      end

      context 'when rails ENV is development' do
        before do
          stub_const('Rails', class_double('Rails', env: 'development'))
        end

        it 'sets fallback to true' do
          expect(subject.fallback).to eq(true)
        end
      end

      context 'when rails ENV is test' do
        before do
          stub_const('Rails', class_double('Rails', env: 'test'))
        end

        it 'sets fallback to true' do
          expect(subject.fallback).to eq(true)
        end
      end
    end

    context 'when configuration has fallback: true' do
      let(:config) { configuration_with_replicas.merge('multidb' => { 'fallback' => true }) }

      it 'sets @candidates to have only default set of candidates' do
        expect(subject.instance_variable_get(:@candidates).keys).to contain_exactly('default')
      end

      it 'sets @default_candidate to be the fist candidate for the default @candidates' do
        candidates = subject.instance_variable_get(:@candidates)

        expect(subject.instance_variable_get(:@default_candidate)).to eq(candidates['default'].first)
      end

      it 'sets @default_configuration to be the configuration' do
        expect(subject.instance_variable_get(:@default_configuration)).to eq(configuration)
      end

      it 'sets fallback to true' do
        expect(subject.fallback).to eq(true)
      end
    end

    context 'when configuration has default multidb configuration' do
      let(:config) {
        extra = { multidb: { databases: {
          default: {
            adapter: 'sqlite3',
            database: 'spec/test-default.sqlite'
          }
        } } }
        configuration_with_replicas.merge(extra)
      }

      it 'set @candidates default to that configuration and not @default_candidate' do
        candidates        = subject.instance_variable_get(:@candidates)
        default_candidate = subject.instance_variable_get(:@default_candidate)

        expect(candidates[:default].first).not_to eq default_candidate
      end
    end

    context 'when configuration is nil' do
      let(:configuration) { nil }

      it 'set @candidates to an empty hash' do
        expect(subject.instance_variable_get(:@candidates)).to eq({})
      end
    end
  end

  describe '#append' do
    subject { balancer.append(appended_config) }

    let(:config) { configuration_with_replicas.except('multidb') }

    context 'with a basic configuration' do
      let(:appended_config) { { replica4: { database: 'spec/test-replica4.sqlite' } } }

      it 'registers the new candidate set in @candidates' do
        expect { subject }.to change {
          balancer.instance_variable_get(:@candidates)
        }.to include('replica4')
      end

      it 'makes it available for use' do
        subject

        balancer.use(:replica4) do
          expect(balancer.current_connection).to have_database 'test-replica4.sqlite'
        end
      end

      it 'returns the connection name' do
        subject

        balancer.use(:replica4) do
          expect(balancer.current_connection_name).to eq :replica4
        end
      end
    end

    context 'with an alias' do
      let(:appended_config) {
        {
          replica2: {
            database: 'spec/test-replica4.sqlite'
          },
          replica_alias: {
            alias: 'replica2'
          }
        }
      }

      it 'aliases replica4 as replica2' do
        subject

        candidates = balancer.instance_variable_get(:@candidates)

        expect(candidates['replica2']).to eq(candidates['replica_alias'])
      end
    end
  end

  describe '#disconnect!' do
    subject { balancer.disconnect! }

    it 'calls disconnect! on all the candidates' do
      candidate1 = instance_double(Multidb::Candidate, disconnect!: nil)
      candidate2 = instance_double(Multidb::Candidate, disconnect!: nil)

      candidates = { 'replica1' => [candidate1], 'replica2' => [candidate2] }

      balancer.instance_variable_set(:@candidates, candidates)

      subject

      expect(candidate1).to have_received(:disconnect!)
      expect(candidate2).to have_received(:disconnect!)
    end
  end

  describe '#get' do
    subject { balancer.get(name) }

    let(:name) { :replica1 }
    let(:candidates) { balancer.instance_variable_get(:@candidates) }

    context 'when there is only one candidate' do
      it 'returns the candidate' do
        is_expected.to eq candidates['replica1'].first
      end
    end

    context 'when there is more than one candidate' do
      it 'returns a random candidate' do
        returned = Set.new
        100.times do
          returned << balancer.get(:replica3)
        end

        expect(returned).to match_array candidates['replica3']
      end
    end

    context 'when the name has no configuration' do
      let(:name) { :other }

      context 'when fallback is false' do
        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError, /No such database connection/)
        end
      end

      context 'when fallback is true' do
        before do
          balancer.fallback = true
        end

        it 'returns the default connection' do
          is_expected.to eq candidates[:default].first
        end
      end

      context 'when given a block' do
        it 'yields the candidate' do
          expect { |y|
            balancer.get(:replica1, &y)
          }.to yield_with_args(candidates[:replica1].first)
        end
      end
    end
  end

  describe '#use' do
    context 'with an undefined connection' do
      it 'raises exception' do
        expect {
          balancer.use(:something) { nil }
        }.to raise_error(ArgumentError)
      end
    end

    context 'with a configured connection' do
      let(:global_config) { true }

      it 'returns default connection on :default' do
        balancer.use(:default) do
          expect(balancer.current_connection).to have_database 'test.sqlite'
        end
      end

      it 'returns results instead of relation' do
        foobar_class = Class.new(ActiveRecord::Base) do
          self.table_name = 'foo_bars'
        end

        res = balancer.use(:replica1) do
          ActiveRecord::Migration.verbose = false
          ActiveRecord::Schema.define(version: 1) { create_table :foo_bars }
          foobar_class.where(id: 42)
        end

        expect(res).to eq []
      end
    end

    it 'returns replica connection' do
      balancer.use(:replica1) do
        expect(balancer.current_connection).to have_database 'test-replica1.sqlite'
      end
    end

    it 'returns supports nested replica connection' do
      balancer.use(:replica1) do
        balancer.use(:replica2) do
          expect(balancer.current_connection).to have_database 'test-replica2.sqlite'
        end
      end
    end

    it 'returns preserves state when nesting' do
      balancer.use(:replica1) do
        balancer.use(:replica2) do
          expect(balancer.current_connection).to have_database 'test-replica2.sqlite'
        end

        expect(balancer.current_connection).to have_database 'test-replica1.sqlite'
      end
    end

    it 'returns the parent connection for aliases' do
      expect(balancer.use(:replica1)).not_to eq balancer.use(:replica_alias)
      expect(balancer.use(:replica2)).to eq balancer.use(:replica_alias)
    end

    context 'when there are multiple candidates' do
      it 'returns random candidate' do
        names = []
        100.times do
          balancer.use(:replica3) do
            list = balancer.current_connection.execute('pragma database_list')
            names.push(File.basename(list.first&.[]('file')))
          end
        end
        expect(names.uniq).to match_array %w[test-replica3-1.sqlite test-replica3-2.sqlite]
      end
    end
  end

  describe '#current_connection' do
    subject { balancer.current_connection }

    context 'when no alternate connection is active' do
      let(:global_config) { true }

      it 'returns main connection by default' do
        is_expected.to have_database 'test.sqlite'

        is_expected.to eq ActiveRecord::Base.retrieve_connection
      end
    end

    context 'when an alternate connection is active' do
      before do
        Thread.current[:multidb] = { connection: 'a different connection' }
      end

      it 'returns the thread local connection' do
        is_expected.to eq 'a different connection'
      end
    end
  end

  describe '#current_connection_name' do
    subject { balancer.current_connection_name }

    context 'when no alternate connection is active' do
      it 'returns default connection name for default connection' do
        is_expected.to eq :default
      end
    end

    context 'when an alternate connection is active' do
      before do
        Thread.current[:multidb] = { connection_name: :replica1 }
      end

      it 'returns the thread local connection' do
        is_expected.to eq :replica1
      end
    end
  end

  describe 'class delegates' do
    let(:balancer) {
      instance_double('Multidb::Balancer',
                      use: nil,
                      current_connection: nil,
                      current_connection_name: nil,
                      disconnect!: nil)
    }

    before do
      Multidb.instance_variable_set(:@balancer, balancer)
    end

    it 'delegates use to the balancer' do
      described_class.use(:name)

      expect(balancer).to have_received(:use).with(:name)
    end

    it 'delegates current_connection to the balancer' do
      described_class.current_connection

      expect(balancer).to have_received(:current_connection)
    end

    it 'delegates current_connection_name to the balancer' do
      described_class.current_connection_name

      expect(balancer).to have_received(:current_connection_name)
    end

    it 'delegates disconnect! to the balancer' do
      described_class.disconnect!

      expect(balancer).to have_received(:disconnect!)
    end
  end
end
