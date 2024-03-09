require_relative 'base'

module RrxJobs::Configuration
  class Queue < Base
    DEFAULT_PRIORITY = 100

    def self.create(value)
      raise ArgumentError, 'Hash expected' unless value.is_a?(Hash)
      value.map do |name, config|
        Queue.new(name:, **config)
      end
    end

    attribute :name, :symbol
    attribute :priority, :integer, default: DEFAULT_PRIORITY
    attribute :group, :symbol

    validates_presence_of :name
    validates_numericality_of :priority, only_integer: true, greater_than_or_equal_to: 0
  end
end
