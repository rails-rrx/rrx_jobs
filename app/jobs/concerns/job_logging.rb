# frozen_string_literal: true

module Concerns
  module JobLogging
    extend ActiveSupport::Concern

    included do
      around_perform :perform_with_logger

      private

      def perform_with_logger
        name = self.class.name.underscore
        self.logger = logger.scoped(
          name:,
          tags: {
            request_id: job_id,
            queue: queue_name
          }
        )
        logger.debug 'Starting job %s %s' % [name, job_id]
        begin
          yield
          logger.debug 'Completed job %s %s' % [name, job_id]
        rescue StandardError => x
          logger.warn 'Job %s %s exception: %s' % [name, job_id, x]
          raise
        end
      end

    end
  end
end
