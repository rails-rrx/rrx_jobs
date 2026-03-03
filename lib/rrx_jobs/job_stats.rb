require_relative 'job_manager'

module RrxJobs
  class JobStats
    class StatBucket
      attr_accessor :pending, :failed, :running

      def initialize
        @pending = 0
        @failed  = 0
        @running = 0
      end

      def add(row)
        @pending += row['pending'].to_i
        @failed  += row['failed'].to_i
        @running += row['running'].to_i
      end
    end

    class << self
      def stats(groups: true, total: true)
        buckets = Hash[buckets_for(JobManager.config.queues)]
        buckets.update Hash[buckets_for(JobManager.config.groups.values)] if groups
        buckets[:total] = total_bucket = StatBucket.new if total

        db_stats.each do |queue, row|
          queue_config = JobManager.config.queues_by_name[queue]
          next unless queue_config

          buckets[queue]&.add(row)
          buckets[queue_config.group]&.add(row) if groups && queue_config.group
          total_bucket.add(row) if total
        end

        buckets
      end

      private

      def db_stats
        jobs     = SolidQueue::Job.arel_table
        claimed  = SolidQueue::ClaimedExecution.arel_table
        failed   = SolidQueue::FailedExecution.arel_table
        ready    = SolidQueue::ReadyExecution.arel_table

        # LEFT JOINs to determine state per job
        query = jobs
          .project(
            jobs[:queue_name],
            Arel::Nodes::Case.new
              .when(claimed[:job_id].not_eq(nil)).then(0).else(1).sum.as('running'),
            Arel::Nodes::Case.new
              .when(failed[:job_id].not_eq(nil)).then(0).else(1)
              .then(Arel::Nodes::Case.new
                .when(claimed[:job_id].eq(nil).and(failed[:job_id].eq(nil))).then(1).else(0))
              .sum.as('pending'),
            Arel::Nodes::Case.new
              .when(failed[:job_id].not_eq(nil)).then(1).else(0).sum.as('failed')
          )
          .join(claimed, Arel::Nodes::OuterJoin)
          .on(jobs[:id].eq(claimed[:job_id]))
          .join(failed, Arel::Nodes::OuterJoin)
          .on(jobs[:id].eq(failed[:job_id]))
          .where(jobs[:finished_at].eq(nil))
          .group(jobs[:queue_name])
          .order(jobs[:queue_name])

        results = SolidQueue::Job.connection.select_all(query).to_a
        results.index_by { |r| normalized_queue_name(r.delete('queue_name')).to_sym }
      end

      def normalized_queue_name(name)
        prefix = Rails.application.config.active_job.queue_name_prefix.presence || ''
        prefix.length > 0 ? name.delete_prefix("#{prefix}_") : name
      end

      def buckets_for(list)
        list.map { |it| [it.name, StatBucket.new] }
      end
    end
  end
end
