# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Multidb::Candidate do
  subject(:candidate) { described_class.new(name, target) }

  let(:name) { :default }
  let(:config) { configuration_with_replicas.with_indifferent_access.except(:multidb) }
  let(:target) { config }

  describe '#initialize' do
    context 'when target is a config hash' do
      let(:target) { config }

      it 'sets the connection_handler to a new AR connection handler' do
        handler = subject.instance_variable_get(:@connection_handler)
        expect(handler).to an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionHandler)
      end

      it 'merges the name: primary into the hash', rails: '< 6.1' do
        handler = instance_double('ActiveRecord::ConnectionAdapters::ConnectionHandler')
        allow(ActiveRecord::ConnectionAdapters::ConnectionHandler).to receive(:new).and_return(handler)
        allow(handler).to receive(:establish_connection)

        subject

        expect(handler).to have_received(:establish_connection).with(hash_including(name: 'primary'))
      end
    end

    context 'when target is a connection handler' do
      let(:target) { ActiveRecord::ConnectionAdapters::ConnectionHandler.new }

      it 'sets the connection_handler to the passed handler' do
        handler = subject.instance_variable_get(:@connection_handler)
        expect(handler).to eq(target)
      end
    end

    context 'when target is anything else' do
      let(:target) { 'something else' }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, /Connection handler not passed/)
      end
    end

    it 'sets the name to the name' do
      expect(subject.name).to eq name
    end
  end

  describe '#connection' do
    let(:pool) {
      instance_double('ActiveRecord::ConnectionAdapters::ConnectionPool').tap do |o|
        allow(o).to receive(:with_connection).and_yield('a connection')
      end
    }
    let(:target) {
      ActiveRecord::ConnectionAdapters::ConnectionHandler.new.tap do |o|
        allow(o).to receive(:retrieve_connection)
        allow(o).to receive(:retrieve_connection_pool).and_return(pool)
      end
    }

    context 'when given a block' do
      it 'calls retrieve_connection_pool' do
        subject.connection { |_| nil }

        expect(target).to have_received(:retrieve_connection_pool).with(Multidb::Candidate::SPEC_NAME)
      end

      it 'yields a connection object' do
        expect { |y|
          subject.connection(&y)
        }.to yield_with_args('a connection')
      end
    end

    context 'when not given a block' do
      it 'calls retrieve_connection on the handler' do
        subject.connection

        expect(target).to have_received(:retrieve_connection).with(Multidb::Candidate::SPEC_NAME)
      end
    end
  end

  describe '#disconnect!' do
    subject { candidate.disconnect! }

    let(:target) {
      ActiveRecord::ConnectionAdapters::ConnectionHandler.new.tap do |o|
        allow(o).to receive(:clear_all_connections!)
      end
    }

    it 'calls clear_all_connections! on the handler' do
      subject

      expect(target).to have_received(:clear_all_connections!)
    end
  end
end
