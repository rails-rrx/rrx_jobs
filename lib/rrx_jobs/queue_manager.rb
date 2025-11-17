require 'rrx_jobs/engine'

module RrxJobs
  class QueueManager
    # @return [Logger]
    attr_reader :logger

    ##
    # @param [Array<RrxJobs::WorkerConfiguration> queues
    def initialize(worker_configs)
      # @type [Array<RrxJobs::WorkerConfiguration>]
      @configs = worker_configs
      @workers = []
      @logger  = Rails.logger.scoped(name: 'queue-manager')
    end

    def run
      require 'rrx_jobs/queue_worker'

      @configs.each do |config|
        logger.info "Starting #{config.worker_count} workers for #{config.queues}"
        config.worker_count.times { @workers.push RrxJobs::QueueWorker.new(config.queues) }
      end

      @workers.each(&:start)

      stopped = false
      Signal.trap('INT') { stopped = true }

      # Loop until we're interrupted by something (Ctrl+C)
      err = nil
      begin
        until stopped
          sleep 10
          @workers.each(&:check)
        end
        logger.info 'Stop requested...'
      rescue Exception => x
        logger.warn 'Exception occurred: %s' % x.message
        err = x
      end

      stop

      raise err if err
    end

    private

    def stop
      logger.info 'Shutting down workers'
      @workers.each(&:stop)
      sleep 0.02 while running?
    end

    def running?
      @workers.any?(&:running?)
    end

  end
end
