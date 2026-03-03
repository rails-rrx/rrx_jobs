# frozen_string_literal: true

namespace :rrx_jobs do
  desc 'Start solid_queue workers using rrx_jobs configuration'
  task work: :environment do
    require 'solid_queue'
    SolidQueue::Supervisor.start(**Rails.configuration.job.to_solid_queue_options)
  end
end
