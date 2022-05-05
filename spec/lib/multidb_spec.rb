# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Multidb do
  let(:balancer) { instance_double('Multidb::Balancer', use: nil, get: nil, disconnect!: nil) }

  describe '.balancer' do
    subject { described_class.balancer }

    context 'with no configuration' do
      it 'raises exception' do
        expect { subject }.to raise_error(Multidb::NotInitializedError)
      end
    end

    context 'with configuration' do
      before do
        ActiveRecord::Base.establish_connection(configuration_with_replicas)
      end

      it 'returns balancer' do
        is_expected.to be_an_instance_of(Multidb::Balancer)
      end
    end
  end

  describe '.init' do
    subject { described_class.init(config) }

    let(:config) { configuration_with_replicas }

    it 'initializes @balancer' do
      expect { subject }.to change {
        described_class.instance_variable_get(:@balancer)
      }.from(nil).to an_instance_of(Multidb::Balancer)
    end

    it 'initializes the balancer with a configuration object' do
      allow(Multidb::Configuration).to receive(:new)

      subject

      expect(Multidb::Configuration).to have_received(:new).with(config.except('multidb'), config['multidb'])
    end
  end

  describe '.reset!' do
    subject { described_class.reset! }

    before do
      described_class.instance_variable_set(:@balancer, balancer)
    end

    it 'clears @balancer' do
      expect { subject }.to change {
        described_class.instance_variable_get(:@balancer)
      }.from(balancer).to(nil)
    end

    it 'clears the multidb thread local' do
      Thread.current[:multidb] = { some: :value }

      expect { subject }.to change { Thread.current[:multidb] }.to nil
    end
  end

  describe 'balancer delegates' do
    before do
      described_class.instance_variable_set(:@balancer, balancer)
    end

    it 'delegates use to the balancer' do
      described_class.use(:name)

      expect(balancer).to have_received(:use).with(:name)
    end

    it 'delegates get to the balancer' do
      described_class.get(:name)

      expect(balancer).to have_received(:get).with(:name)
    end

    it 'delegates disconnect! to the balancer' do
      described_class.disconnect!

      expect(balancer).to have_received(:disconnect!)
    end
  end
end
