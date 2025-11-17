require_relative 'job_manager'

module RrxJobs
  class JobStats
    class StatBucket
      attr_accessor :pending, :failed, :running

      def initialize
        @pending = 0
        @failed = 0
        @running = 0
      end

      def add(row)
        @pending += row['pending']
        @failed += row['failed']
        @running += row['running']
      end
    end

    class << self
      def stats(groups: true, total: true)
        # @type [Hash<Symbol, StatBucket>]
        buckets = Hash[buckets_for(JobManager.config.queues)]
        buckets.update Hash[buckets_for(JobManager.config.groups.values)] if groups
        buckets[:total] = total_bucket = StatBucket.new if total

        db_stats.each do |queue, row|
          queue_config = JobManager.config.queues_by_name[queue]
          buckets[queue].add row
          buckets[queue_config.group].add row if groups && queue_config.group
          total_bucket.add row if total
        end

        buckets
      end

      private

      def db_stats
        table = Delayed::Job.arel_table
        run_at, locked_at, failed_at = table[:run_at], table[:locked_at], table[:failed_at]

        query = table.project(
          table[:queue],
          Arel::Nodes::Case.new
                           .when(run_at.not_eq(nil).and locked_at.eq(nil).and failed_at.eq(nil))
                           .then(1).else(0).sum.as('pending'),
          Arel::Nodes::Case.new
                           .when(failed_at.eq(nil).and locked_at.not_eq(nil))
                           .then(1).else(0).sum.as('running'),
          Arel::Nodes::Case.new
                           .when(failed_at.not_eq(nil))
                           .then(1).else(0).sum.as('failed'),
          ).group(1).order(1)

        results = Delayed::Job.connection.select_all(query).to_a

        results.index_by { |r| normalized_queue_name(r.delete('queue')).to_sym }
      end

      def normalized_queue_name(name)
        prefix = Rails.application.config.active_job.queue_name_prefix || ''
        prefix.length > 0 ? name.delete_prefix(prefix + '_') : name
      end

      def stats_sum(stats, *keys)
        summary = {'pending' => 0, 'failed' => 0, 'running' => 0 }
        stats.each do |queue, queue_stats|
          if keys.empty? or keys.include? queue
            queue_stats.each { |stat, value| summary[stat] += value }
          end
        end
        summary
      end

      def buckets_for(list)
        list.map{|it| [it.name, StatBucket.new]}
      end
    end
  end
end
