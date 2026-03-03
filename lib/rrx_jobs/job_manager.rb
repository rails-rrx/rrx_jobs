module RrxJobs
  class JobManager
    class << self
      def reset
        SolidQueue::FailedExecution.all.delete_all
        SolidQueue::ReadyExecution.all.delete_all
      end

      def pending
        SolidQueue::Job.where(finished_at: nil)
                       .where.not(id: SolidQueue::ClaimedExecution.select(:job_id))
                       .where.not(id: SolidQueue::FailedExecution.select(:job_id))
      end

      def failed
        SolidQueue::Job.where(id: SolidQueue::FailedExecution.select(:job_id))
      end

      def running
        SolidQueue::Job.where(id: SolidQueue::ClaimedExecution.select(:job_id))
      end

      def all
        SolidQueue::Job.all
      end

      # Order by running=0, pending=1, failed=2.
      # Uses a searched CASE (no base expression) so each WHEN can be an IN subquery.
      def state_order
        job_table = SolidQueue::Job.arel_table
        claimed   = SolidQueue::ClaimedExecution.select(:job_id)
        failed    = SolidQueue::FailedExecution.select(:job_id)

        Arel::Nodes::Case.new
                         .when(job_table[:id].in(claimed.arel)).then(0)
                         .when(job_table[:id].in(failed.arel)).then(2)
                         .else(1)
      end

      # Order by scheduled time, most recent first
      def queue_order(reverse: false)
        SolidQueue::Job.arel_table[:scheduled_at].send(reverse ? :asc : :desc)
      end

      # @return [RrxJobs::Configuration::Jobs]
      def config
        Rails.configuration.job
      end
    end
  end
end
