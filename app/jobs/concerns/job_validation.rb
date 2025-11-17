# frozen_string_literal: true

module Concerns
  module JobValidation
    extend ActiveSupport::Concern

    prepended do
      before_enqueue :validate_queue
    end

    class InvalidQueueName < StandardError; end

    private

    def validate_queue
      raise InvalidQueueName, "Cannot send to #{self.class.name} to undefined queue: #{queue_name}" unless valid_queue?(queue_name)
    end

    def valid_queue?(name)
      Rails.configuration.job&.has_queue?(name.to_sym)
    end
  end
end
