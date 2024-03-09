require 'active_model'
require 'active_support/core_ext'
require 'didja_rails/types'
require 'delayed_job_active_record'
require_relative 'worker'
require_relative 'queue'
require_relative 'group'
require_relative 'metrics'

module RrxJobs::Configuration
  class Jobs < Base
    attribute :sleep_delay, :integer, default: 30
    attribute :max_attempts, :integer, default: 5
    attribute :max_run_time, :duration, default: 1.hours

    # @return [Array<QueueConfiguration>]
    attr_reader :queues
    attr_reader :workers
    attr_reader :groups
    attr_reader :metrics

    validates_numericality_of :sleep_delay,
                              only_integer: true,
                              greater_than: 0

    validates_numericality_of :max_attempts,
                              only_integer: true,
                              greater_than_or_equal_to: 0

    validates_inclusion_of :max_run_time,
                           in: 30.seconds..6.hours,
                           message: 'Max run time must be between 30 seconds and 6 hours'

    validate :validate_config

    def initialize
      super
      @metrics = Metrics.new
    end

    def workers=(val)
      @workers = Worker.create(val)
      update_groups
    end

    def workers!
      raise 'Job workers are not configured' unless @workers
      @workers
    end

    def queues=(val)
      @queues = Queue.create(val)
      @queues_by_name = @queues.index_by(&:name).with_indifferent_access.freeze
      update_groups
    end

    def queues!
      raise 'Job queues are not configured' unless @queues
      @queues
    end

    def queues_by_name
      raise 'Job queues are not configured' unless @queues_by_name
      @queues_by_name
    end

    def has_queue?(name)
      queues_by_name.key? name.to_sym
    end

    def queue_names
      queues_by_name.keys
    end

    def queue_or_group?(name)
      queues_by_name.key?(name) or groups.key?(name)
    end

    ##
    # Return queue configs for DelayedJob worker
    def queue_attributes
      queues!.index_by(&:name).transform_values do |queue|
        { priority: queue.priority }
      end
    end

    def apply!
      if queues
        # Only initialize if the project has configured queues
        Delayed::Worker.destroy_failed_jobs = false
        Delayed::Worker.sleep_delay = sleep_delay
        Delayed::Worker.max_attempts = max_attempts
        Delayed::Worker.max_run_time = max_run_time
        Delayed::Worker.read_ahead = 1
        Delayed::Worker.logger = Rails.logger.scoped(name: 'delayed-job')
        Delayed::Worker.default_priority = 100
        Delayed::Worker.queue_attributes = queue_attributes
      end
    end

    private

    def update_groups
      if queues
        @groups ||= queues.select(&:group).group_by(&:group).map do |group, queues|
          Group.new(name: group, queues: queues.map(&:name))
        end.index_by(&:name).with_indifferent_access.freeze

        workers&.each {|w| w.update_groups(groups) }
      end
    end

    def validate_config
      worker_queues = Set.new

      if workers&.empty?
        errors.add :workers, 'cannot be empty'
      else
        workers&.each_with_index do |w, i|
          w.queues.each {|q| worker_queues.add(q) }
          unless w.valid?
            w.errors.full_messages.each do |msg|
              errors.add :worker, "##{i} #{msg}"
            end
          end
        end
      end

      if queues&.empty?
        errors.add :queues, 'cannot be empty'
      else
        queues&.each do |q|
          unless !workers || worker_queues.include?(q.name)
            errors.add :queue, "#{q.name} has no matching worker"
          end
          unless q.valid?
            q.errors.full_messages.each do |msg|
              errors.add :queue, "#{q.name} #{msg}"
            end
          end
        end
      end

      metrics.errors.full_messages.each {|msg| errors.add(:metrics, msg) } unless metrics.valid?
    end
  end
end
