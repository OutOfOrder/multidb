# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Multidb::Configuration do
  subject { described_class.new(config.except(:multidb), config[:multidb]) }

  let(:config) { configuration_with_replicas.with_indifferent_access }

  describe '#initialize' do
    it 'sets the default_handler to the AR connection handler' do
      expect(subject.default_handler).to eq(ActiveRecord::Base.connection_handler)
    end

    it 'sets the default_adapter to the main configuration' do
      expect(subject.default_adapter).to eq config.except(:multidb)
    end

    it 'sets the raw_configuration to the multidb configuration' do
      expect(subject.raw_configuration).to eq config[:multidb]
    end
  end
end
