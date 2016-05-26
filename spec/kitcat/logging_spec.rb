require 'spec_helper'

describe Kitcat::Logging do
  module Kitcat
    class SampleStrategy
    end
  end

  subject do
    Kitcat::Logging.new(migration_strategy, migration_name)
  end

  let(:migration_strategy) { Kitcat::SampleStrategy.new }
  let(:migration_name) { SecureRandom.hex }

  describe '#build_migration_name' do
    context 'when no migration name is given' do
      let(:migration_name) { nil }

      it 'returns a name based on strategy class name' do
        expect(subject.send(:build_migration_name, migration_name, migration_strategy)).to eq(migration_strategy.class.name.delete(':').underscore.upcase)
      end
    end

    context 'when migration name is given' do
      before do
        expect(migration_name).not_to be_blank
      end

      it 'returns that name' do
        expect(subject.send(:build_migration_name, migration_name, migration_strategy)).to eq(migration_name.upcase)
      end
    end

    context 'when migration name has non-word characters' do
      let(:migration_name) { "   foo   _123_ bar  \r\n matcho" }
      it 'removes them' do
        expect(subject.send(:build_migration_name, migration_name, migration_strategy)).to eq('FOO_123_BARMATCHO')
      end
    end
  end

  describe '#log_file_path' do
    it 'returns a file name which is based on the migration name and timestamp' do
      now = Time.now
      timestamp = now.to_s(:number)

      Timecop.freeze(now) do
        expect(subject.log_file_path).to end_with("log/migration-#{subject.migration_name}-#{timestamp}.log")
      end
    end
  end
end
