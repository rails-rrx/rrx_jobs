# frozen_string_literal: true

require_relative 'rrx_jobs/version'
require 'rrx_jobs/engine'
require 'active_job'
require 'active_support'
require 'rrx_jobs/job_manager'
require 'rrx_jobs/job_stats'

module RrxJobs
  class Error < StandardError; end
end
