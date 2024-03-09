module RrxJobs
  module ControllerExtensions
    # @param [Symbol] action Action name
    # @param [Class] job_class Class that inherits from DidjaJob
    # @param [Array<any>] job_args
    def job_action(action, job_class = nil, *job_args, &block)
      define_method action do
        job = if job_class
                job_args = instance_exec(&block) if job_args.empty? && block
                raise ArgumentError, 'Job arguments must be an array' unless job_args.is_a?(Array)
                job_class.perform_later *job_args
              else
                instance_exec(&block)
              end

        raise "Invalid job response from action implementation: #{job}" unless job.is_a?(DidjaJob)

        render status: :created, json: {
          message: "Successfully submitted job #{job.job_id} to #{job.queue_name} queue",
          job: {
            id: job.job_id,
            type: job.class.name,
            queue: job.queue_name,
            args: job.arguments
          }
        }
      end
    end
  end
end
