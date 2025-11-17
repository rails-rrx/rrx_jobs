module RrxJobs
  class JobManager
    class << self
      delegate :all, :arel_table, to: Delayed::Job

      def reset
        pending.delete_all
        failed.delete_all
      end

      def pending
        Delayed::Job.where(failed_at: nil, locked_at: nil)
      end

      def failed
        Delayed::Job.where.not(failed_at: nil)
      end

      def running
        Delayed::Job.where(failed_at: nil).where.not(locked_at: nil)
      end

      def failed_condition(failed = true)
        arel_table[:failed_at].send(failed ? :not_eq : :eq, nil)
      end

      def locked_condition(locked = true)
        arel_table[:locked_at].send(locked ? :not_eq : :eq, nil)
      end

      def pending_condition
        failed_condition(false).and locked_condition(false)
      end

      def running_condition
        failed_condition(false).and locked_condition
      end

      # Order by running, pending then failed
      def state_order
        Arel.case
            .when(running_condition).then(0)
            .when(pending_condition).then(1)
            .else(2)
      end

      # Order by queued execution time, most recent first
      def queue_order(reverse: false)
        arel_table[:run_at].send(reverse ? :asc : :desc)
      end

      # @return [RrxJobs::JobConfiguration]
      def config
        Rails.configuration.job
      end
    end
  end
end
