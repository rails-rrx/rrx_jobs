# frozen_string_literal: true

require 'rails_helper'

describe RrxJobs::JobStats, :solid_queue do
  # Configure a minimal job setup used by JobStats (which calls JobManager.config)
  let(:job_config) do
    RrxJobs::Configuration::Jobs.new.tap do |c|
      c.queues  = { critical: { priority: 10 }, default: { priority: 100 } }
      c.workers = { 'critical,default' => 2 }
    end
  end

  before do
    allow(RrxJobs::JobManager).to receive(:config).and_return(job_config)
    # Ensure no queue_name_prefix so normalized_queue_name is a no-op
    allow(Rails.application.config.active_job).to receive(:queue_name_prefix).and_return(nil)
  end

  describe '.stats' do
    context 'with no jobs' do
      it 'returns buckets with zero counts for each queue' do
        result = described_class.stats
        expect(result[:critical].pending).to eq 0
        expect(result[:default].failed).to  eq 0
      end

      it 'includes a :total bucket' do
        result = described_class.stats
        expect(result).to have_key(:total)
      end
    end

    context 'with some jobs' do
      before do
        create_sq_job(queue_name: 'critical')
        create_sq_job(queue_name: 'critical')
        make_failed(create_sq_job(queue_name: 'default'))
        make_claimed(create_sq_job(queue_name: 'default'))
      end

      it 'counts pending jobs per queue' do
        result = described_class.stats
        expect(result[:critical].pending).to eq 2
      end

      it 'counts failed jobs per queue' do
        result = described_class.stats
        expect(result[:default].failed).to eq 1
      end

      it 'counts running jobs per queue' do
        result = described_class.stats
        expect(result[:default].running).to eq 1
      end

      it 'rolls up totals across queues' do
        result = described_class.stats
        expect(result[:total].pending).to eq 2
        expect(result[:total].failed).to  eq 1
        expect(result[:total].running).to eq 1
      end
    end

    context 'with groups: false' do
      before do
        create_sq_job(queue_name: 'critical')
      end

      it 'does not include group buckets' do
        result = described_class.stats(groups: false)
        # Only queue-level and :total keys expected
        expect(result.keys).to contain_exactly(:critical, :default, :total)
      end
    end

    context 'with total: false' do
      it 'does not include a :total bucket' do
        result = described_class.stats(total: false)
        expect(result).not_to have_key(:total)
      end
    end

    context 'with queue_name_prefix configured' do
      before do
        allow(Rails.application.config.active_job)
          .to receive(:queue_name_prefix).and_return('myapp')
        create_sq_job(queue_name: 'myapp_critical')
      end

      it 'strips the prefix from queue names before matching buckets' do
        result = described_class.stats
        expect(result[:critical].pending).to eq 1
      end
    end

    context 'with unknown queue in db' do
      before do
        # Job in a queue not in config — should be silently skipped
        create_sq_job(queue_name: 'unknown_queue')
      end

      it 'does not raise and ignores unrecognised queues' do
        expect { described_class.stats }.not_to raise_error
      end

      it 'does not add the unknown queue to the result' do
        result = described_class.stats
        expect(result).not_to have_key(:unknown_queue)
      end
    end
  end
end
