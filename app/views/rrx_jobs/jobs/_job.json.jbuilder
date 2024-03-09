json.(job, :id, :queue, :created_at, :priority, :attempts)
json.type job.payload_object.job_data['job_class']
json.job_id job.payload_object.job_data['job_id']
json.arguments job.payload_object.job_data['arguments']
json.status case
            when job.failed_at
              'failed'
            when job.locked_at
              'running'
            else
              'pending'
            end

if job.failed_at
  json.(job, :failed_at, :last_error)
end
