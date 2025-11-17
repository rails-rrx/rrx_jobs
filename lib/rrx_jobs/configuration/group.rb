require_relative 'base'

module RrxJobs::Configuration
  class Group < Base
    attribute :name, :symbol
    attribute :queues
  end
end
