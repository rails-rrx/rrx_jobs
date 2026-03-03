# frozen_string_literal: true

require 'rails_helper'

describe RrxJobs::Configuration::Jobs do
  subject(:config) { described_class.new }

  let(:basic_queues) do
    {
      critical: { priority: 10 },
      default:  { priority: 100 }
    }
  end

  let(:basic_workers) do
    { 'critical,default' => 2 }
  end

  # -----------------------------------------------------------------------
  # Attribute defaults
  # -----------------------------------------------------------------------
  describe 'defaults' do
    it 'defaults sleep_delay to 30' do
      expect(config.sleep_delay).to eq 30
    end
  end

  # -----------------------------------------------------------------------
  # Validations
  # -----------------------------------------------------------------------
  describe 'validations' do
    context 'when no workers or queues are set' do
      it 'is invalid' do
        expect(config).not_to be_valid
      end

      it 'reports empty workers error' do
        config.valid?
        expect(config.errors[:workers]).to include('cannot be empty')
      end

      it 'reports empty queues error' do
        config.valid?
        expect(config.errors[:queues]).to include('cannot be empty')
      end
    end

    context 'with a negative sleep_delay' do
      before do
        config.queues  = basic_queues
        config.workers = basic_workers
        config.sleep_delay = -1
      end

      it 'is invalid' do
        expect(config).not_to be_valid
      end
    end

    context 'with valid workers and queues' do
      before do
        config.queues  = basic_queues
        config.workers = basic_workers
      end

      it 'is valid' do
        expect(config).to be_valid
      end
    end

    context 'when a queue has no matching worker' do
      before do
        config.queues  = { critical: { priority: 10 }, orphan: { priority: 50 } }
        config.workers = { 'critical' => 1 }
      end

      it 'is invalid' do
        expect(config).not_to be_valid
        expect(config.errors[:queue].join).to match(/orphan/)
      end
    end
  end

  # -----------------------------------------------------------------------
  # Queue helpers
  # -----------------------------------------------------------------------
  describe '#queue_names' do
    before do
      config.queues  = basic_queues
      config.workers = basic_workers
    end

    it 'returns the configured queue names as symbols' do
      expect(config.queue_names).to contain_exactly(:critical, :default)
    end
  end

  describe '#has_queue?' do
    before do
      config.queues  = basic_queues
      config.workers = basic_workers
    end

    it 'returns true for known queues' do
      expect(config.has_queue?(:critical)).to be true
    end

    it 'returns false for unknown queues' do
      expect(config.has_queue?(:unknown)).to be false
    end
  end

  describe '#queue_names_with_priority' do
    before do
      config.queues  = basic_queues
      config.workers = basic_workers
    end

    it 'returns an array of hashes with name and priority' do
      result = config.queue_names_with_priority
      expect(result).to include(hash_including(name: 'critical', priority: 10))
      expect(result).to include(hash_including(name: 'default',  priority: 100))
    end
  end

  # -----------------------------------------------------------------------
  # to_solid_queue_options
  # -----------------------------------------------------------------------
  describe '#to_solid_queue_options' do
    before do
      config.queues      = basic_queues
      config.workers     = basic_workers
      config.sleep_delay = 5
    end

    subject(:opts) { config.to_solid_queue_options }

    it 'returns a hash with :workers and :dispatchers keys' do
      expect(opts).to include(:workers, :dispatchers)
    end

    it 'maps worker_count to :threads' do
      worker = opts[:workers].first
      expect(worker[:threads]).to eq 2
    end

    it 'includes all configured queues in the worker entry' do
      worker = opts[:workers].first
      expect(worker[:queues]).to contain_exactly('critical', 'default')
    end

    it 'sets dispatcher polling_interval from sleep_delay' do
      dispatcher = opts[:dispatchers].first
      expect(dispatcher[:polling_interval]).to eq 5
    end

    it 'raises when workers are not configured' do
      bare = described_class.new
      expect { bare.to_solid_queue_options }.to raise_error(RuntimeError, /workers are not configured/)
    end
  end

  # -----------------------------------------------------------------------
  # workers!  / queues!
  # -----------------------------------------------------------------------
  describe '#workers!' do
    it 'raises when workers are not set' do
      expect { config.workers! }.to raise_error(RuntimeError, /workers are not configured/)
    end

    it 'returns workers when set' do
      config.queues  = basic_queues
      config.workers = basic_workers
      expect(config.workers!).not_to be_empty
    end
  end

  describe '#queues!' do
    it 'raises when queues are not set' do
      expect { config.queues! }.to raise_error(RuntimeError, /queues are not configured/)
    end
  end
end
