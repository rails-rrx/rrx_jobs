# frozen_string_literal: true

require 'rails_helper'

describe RrxJobs::JobManager, :solid_queue do
  # -----------------------------------------------------------------------
  # Scopes
  # -----------------------------------------------------------------------
  describe '.pending' do
    it 'returns jobs with no finished_at that are not claimed or failed' do
      job = create_sq_job(queue_name: 'default')
      expect(described_class.pending).to include(job)
    end

    it 'excludes claimed jobs' do
      job = make_claimed(create_sq_job)
      expect(described_class.pending).not_to include(job)
    end

    it 'excludes failed jobs' do
      job = make_failed(create_sq_job)
      expect(described_class.pending).not_to include(job)
    end

    it 'excludes finished jobs' do
      job = create_sq_job(finished_at: 1.second.ago)
      expect(described_class.pending).not_to include(job)
    end
  end

  describe '.failed' do
    it 'returns jobs with a failed execution' do
      job = make_failed(create_sq_job)
      expect(described_class.failed).to include(job)
    end

    it 'does not include pending jobs' do
      job = create_sq_job
      expect(described_class.failed).not_to include(job)
    end
  end

  describe '.running' do
    it 'returns jobs with a claimed execution' do
      job = make_claimed(create_sq_job)
      expect(described_class.running).to include(job)
    end

    it 'does not include pending jobs' do
      job = create_sq_job
      expect(described_class.running).not_to include(job)
    end
  end

  describe '.all' do
    it 'returns all jobs regardless of state' do
      pending_job = create_sq_job
      failed_job  = make_failed(create_sq_job)
      claimed_job = make_claimed(create_sq_job)
      expect(described_class.all).to include(pending_job, failed_job, claimed_job)
    end
  end

  # -----------------------------------------------------------------------
  # reset
  # -----------------------------------------------------------------------
  describe '.reset' do
    it 'deletes all failed executions' do
      make_failed(create_sq_job)
      described_class.reset
      expect(SolidQueue::FailedExecution.count).to eq 0
    end

    it 'deletes all ready executions' do
      make_ready(create_sq_job)
      described_class.reset
      expect(SolidQueue::ReadyExecution.count).to eq 0
    end
  end

  # -----------------------------------------------------------------------
  # state_order
  # -----------------------------------------------------------------------
  describe '.state_order' do
    it 'returns an Arel::Nodes::Case node' do
      expect(described_class.state_order).to be_a(Arel::Nodes::Case)
    end

    it 'orders running=0, pending=1, failed=2 when used in a query' do
      pending_job = create_sq_job(queue_name: 'q')
      failed_job  = make_failed(create_sq_job(queue_name: 'q'))
      running_job = make_claimed(create_sq_job(queue_name: 'q'))

      ordered = SolidQueue::Job.order(described_class.state_order).map(&:id)
      expect(ordered.first).to eq running_job.id
      expect(ordered.last).to  eq failed_job.id
    end
  end

  # -----------------------------------------------------------------------
  # queue_order
  # -----------------------------------------------------------------------
  describe '.queue_order' do
    it 'returns an Arel node usable in an ORDER BY' do
      node = described_class.queue_order
      expect(node).to be_a(Arel::Nodes::Descending)
    end

    it 'returns an ascending node when reverse: true' do
      node = described_class.queue_order(reverse: true)
      expect(node).to be_a(Arel::Nodes::Ascending)
    end
  end
end
