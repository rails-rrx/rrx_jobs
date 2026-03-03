# frozen_string_literal: true

# Helpers for inserting SolidQueue test records without the full ActiveJob stack.
module SolidQueueHelpers
  # Insert a bare solid_queue_jobs row and return the id.
  def create_sq_job(queue_name: 'default', class_name: 'TestJob', finished_at: nil)
    SolidQueue::Job.create!(
      queue_name:,
      class_name:,
      arguments:  '{}',
      priority:   0,
      finished_at:
    )
  end

  def make_ready(job)
    SolidQueue::ReadyExecution.create!(job_id: job.id, queue_name: job.queue_name, priority: job.priority)
    job
  end

  def make_claimed(job)
    process = SolidQueue::Process.create!(
      kind:             'worker',
      last_heartbeat_at: Time.current,
      pid:              Process.pid,
      hostname:         'test',
      name:             "worker-#{SecureRandom.hex(4)}"
    )
    SolidQueue::ClaimedExecution.create!(job_id: job.id, process_id: process.id)
    job
  end

  def make_failed(job, error: 'RuntimeError: boom')
    SolidQueue::FailedExecution.create!(job_id: job.id, error:)
    job
  end
end

RSpec.configure do |config|
  config.include SolidQueueHelpers, :solid_queue
end
