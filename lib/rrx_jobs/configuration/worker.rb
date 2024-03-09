require_relative 'base'

module RrxJobs::Configuration
  class Worker < Base
    attr_reader :queues
    attribute :worker_count, :integer, default: 1

    validates_numericality_of :worker_count,
                              only_integer: true,
                              greater_than: 0

    validate :validate_queues

    def self.create(value)
      raise ArgumentError, "workers must be a hash #{value}" unless value.is_a?(Hash)
      value.map do |queues, worker_count|
        Worker.new(queues:, worker_count:)
      end
    end

    def queues=(val)
      @queues = case val
                when String
                  val.split(/[\s,]+/).map(&:to_sym)
                when Array
                  val.map(&:to_sym)
                when Symbol
                  [val]
                else
                  raise ArgumentError
                end
    end

    def update_groups(groups)
      @queues = @queues.map do |q|
        groups.fetch(q, nil)&.queues || q
      end.flatten
    end

    private

    def validate_queues
      errors.add :queues, 'are empty' unless queues.present?
    end
  end
end
