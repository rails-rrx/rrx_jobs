# frozen_string_literal: true

require 'active_job'
require 'rrx_logging'
require_relative 'concerns/job_validation'
require_relative 'concerns/job_logging'

class RrxJob < ActiveJob::Base
  self.reset_callbacks :enqueue
  self.reset_callbacks :perform

  include Concerns::JobValidation
  include Concerns::JobLogging
end
