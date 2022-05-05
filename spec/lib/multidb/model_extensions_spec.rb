# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Multidb::ModelExtensions do
  it 'includes the Multidb::Connection module into the class methods of ActiveRecord::Base' do
    expect(ActiveRecord::Base.singleton_class.included_modules).to include Multidb::Connection
  end

  describe Multidb::Connection do
    describe '.establish_connection' do
      subject { ActiveRecord::Base.establish_connection(configuration_with_replicas) }

      it 'initializes multidb' do
        allow(Multidb).to receive(:init)

        subject

        expect(Multidb).to have_received(:init)
      end
    end

    describe '.connection' do
      subject { klass.connection }

      let(:klass) {
        Class.new do
          def self.connection
            'AR connection'
          end

          include Multidb::ModelExtensions
        end
      }

      context 'when multidb is not initialized' do
        it 'calls AR::Base.connection' do
          is_expected.to eq('AR connection')
        end
      end

      context 'when multidb is initialized' do
        let(:balancer) { instance_double('Multidb::Balancer', current_connection: 'Multidb connection') }

        before do
          Multidb.instance_variable_set(:@balancer, balancer)
        end

        it 'calls current_connection on the balancer' do
          subject

          expect(balancer).to have_received(:current_connection)
        end

        it 'returns the balancer connection' do
          is_expected.to eq('Multidb connection')
        end
      end
    end
  end
end
