# frozen_string_literal: true

# Creates all solid_queue tables inline in the SQLite test database so that
# RrxJobs::JobManager and RrxJobs::JobStats can be exercised without running
# the full solid_queue install generator.
ActiveRecord::Schema.define do
  create_table :solid_queue_jobs, force: true do |t|
    t.string   :queue_name,     null: false
    t.string   :class_name,     null: false
    t.text     :arguments
    t.integer  :priority,       default: 0, null: false
    t.string   :active_job_id
    t.datetime :scheduled_at
    t.datetime :finished_at
    t.string   :concurrency_key
    t.timestamps null: false
  end

  create_table :solid_queue_ready_executions, force: true do |t|
    t.bigint   :job_id,     null: false
    t.string   :queue_name, null: false
    t.integer  :priority,   default: 0, null: false
    t.datetime :created_at, null: false
  end

  create_table :solid_queue_claimed_executions, force: true do |t|
    t.bigint   :job_id,     null: false
    t.bigint   :process_id
    t.datetime :created_at, null: false
  end

  create_table :solid_queue_failed_executions, force: true do |t|
    t.bigint   :job_id,     null: false
    t.text     :error
    t.datetime :created_at, null: false
  end

  create_table :solid_queue_scheduled_executions, force: true do |t|
    t.bigint   :job_id,       null: false
    t.string   :queue_name,   null: false
    t.integer  :priority,     default: 0, null: false
    t.datetime :scheduled_at, null: false
    t.datetime :created_at,   null: false
  end

  create_table :solid_queue_processes, force: true do |t|
    t.string   :kind,             null: false
    t.datetime :last_heartbeat_at, null: false
    t.bigint   :supervisor_id
    t.integer  :pid,              null: false
    t.string   :hostname
    t.text     :metadata
    t.datetime :created_at,       null: false
    t.string   :name,             null: false
  end

  create_table :solid_queue_semaphores, force: true do |t|
    t.string   :key,        null: false
    t.integer  :value,      default: 1, null: false
    t.datetime :expires_at, null: false
    t.timestamps null: false
  end

  create_table :solid_queue_pauses, force: true do |t|
    t.string   :queue_name, null: false
    t.datetime :created_at, null: false
  end
end
