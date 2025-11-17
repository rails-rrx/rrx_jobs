module RrxJobs
  class QueueWorker
    # @return [Logger]
    attr_reader :logger
    attr_reader :queues
    attr_reader :pid

    # @param [Array<String>, Array<Symbol>] queues
    def initialize(queues)
      @queues = queues.map(&:to_s).freeze
      @pid    = nil
      @logger = Rails.logger.scoped(name: 'queue-worker', tags: { queues: @queues })
    end

    def start
      logger.info "Worker starting for #{@queues}"

      @pid = Process.spawn(
        { 'QUEUES' => @queues.join(',') },
        'rake jobs:work',
        [:out, :err] => :out
      )

      logger.info "Worker #{@pid} started for #{@queues}"
    end

    def stop
      if @pid
        logger.info "Worker #{@pid} stopping for #{@queues}"
        Process.kill 'INT', @pid
      end
    end

    def status?
      _, status = Process.waitpid2(@pid, Process::WNOHANG)
      status
    end

    def running?
      result = false
      if @pid
        result = !status? rescue false
        @pid = nil unless result
      end
      result
    end

    ##
    # Check if process running, restart if needed
    def check
      if @pid
        status = status?
        if status
          # Process exited...
          logger.warn "Worker #{@pid} exited unexpectedly with status #{status.exitstatus}"
          @pid = nil
        end
      end

      start unless @pid
    end

  end
end
