json.(job, :id, :queue_name, :class_name, :created_at, :scheduled_at)
json.arguments job.arguments
json.status if job.failed_executions.any?
               'failed'
             elsif job.claimed_executions.any?
               'running'
             else
               'pending'
             end

if (failed = job.failed_executions.first)
  json.failed_at  failed.created_at
  json.last_error failed.error
end
