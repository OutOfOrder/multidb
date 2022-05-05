# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Multidb::LogSubscriberExtension do
  before do
    ActiveRecord::Base.establish_connection(configuration_with_replicas)
  end

  let(:klass) {
    klass = Class.new do
      def sql(event)
        event
      end

      def debug(msg)
        msg
      end

      def color(text, _color, _bold)
        text
      end
    end

    klass.tap do |o|
      o.prepend described_class
    end
  }

  let(:instance) { klass.new }

  it 'prepends the extension into the ActiveRecord::LogSubscriber' do
    expect(ActiveRecord::LogSubscriber.included_modules).to include(described_class)
  end

  describe '#sql' do
    subject { instance.sql(event) }

    let(:event) { instance_double('Event', payload: {}) }

    it 'sets the :default db_name into the event payload' do
      expect { subject }.to change { event.payload }.to include(db_name: :default)
    end

    context 'when a replica is active' do
      it 'sets the db_name into the event payload to the replica' do
        expect {
          Multidb.use(:replica1) { subject }
        }.to change { event.payload }.to include(db_name: :replica1)
      end
    end

    context 'when there is no name returned from the balancer' do
      before do
        allow(Multidb.balancer).to receive(:current_connection_name)
      end

      it 'does not change the payload' do
        expect { subject }.not_to change { event.payload }
      end
    end
  end

  describe '#debug' do
    subject { instance.debug('message') }

    it 'prepends the db name to the message' do
      is_expected.to include('[DB: default]')
    end

    context 'when a replica is active' do
      it 'prepends the replica dbname to the message' do
        Multidb.use(:replica1) {
          is_expected.to include('[DB: replica1')
        }
      end
    end

    context 'when there is no name returned from the balancer' do
      before do
        allow(Multidb.balancer).to receive(:current_connection_name)
      end

      it 'does not prepend to the message' do
        is_expected.to eq('message')
      end
    end
  end
end
