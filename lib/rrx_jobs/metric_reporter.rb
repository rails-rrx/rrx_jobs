module RrxJobs
  class MetricReporter
    include Singleton

    def self.report!
      self.instance.report!
    end

    def config
      @config ||= Rails.application.config.job
    end

    def enabled?
      @enabled ||= config.metrics.enabled?
    end

    def metrics
      @metrics ||= begin
                     require 'didja_rails/metrics'
                     DidjaRails::Metrics.new config.metrics.namespace,
                                             :queue,
                                             pending: :count,
                                             failed:  :count,
                                             running: :count
                   end
    end

    def report!
      raise 'RrxJobs metrics not configured' unless config.metrics.enabled?

      JobStats.stats(total: false).each do |queue, queue_stats|
        metrics.pending[queue] = queue_stats.pending
        metrics.failed[queue]  = queue_stats.failed
        metrics.running[queue] = queue_stats.running
      end

      metrics.report!
    end
  end
end
