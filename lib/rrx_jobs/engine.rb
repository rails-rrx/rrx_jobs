require 'rails'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/railtie'
require 'active_job/railtie'
require 'active_model/railtie'
require 'delayed_job_active_record'
require 'didja_rails/railtie'
require_relative 'configuration/jobs'
require 'jbuilder'

module RrxJobs
  class Engine < Rails::Engine
    railtie_name 'rrx_jobs'
    isolate_namespace RrxJobs

    # paths['config/routes.rb'] = 'app/routes.rb'

    config.job = Configuration::Jobs.new
    config.active_job.queue_adapter = :delayed_job
    # Exclude noisy DelayedJob SQL UPDATE logging
    # config.log_noise_filters << 'Delayed::Backend::ActiveRecord::Job'

    rake_tasks do
      Dir[File.expand_path('../../lib/tasks/*.rake', __dir__)].each { |p| load p }
    end

    initializer 'rrx_jobs.controller_extensions' do
      ActiveSupport.on_load(:action_controller) do
        require_relative 'controller_extensions'
        extend RrxJobs::ControllerExtensions
      end
    end

    initializer 'rrx_jobs.job_table', after: 'active_record.initialize_database' do
      ActiveSupport.on_load(:active_record) do
        db = ActiveRecord::Base.connection rescue nil
        if db
          RrxJobs::Engine.create_delayed_jobs_table db
          RrxJobs::Engine.create_singleton_job_table db
        end
      end
    end

    initializer 'rrx_jobs.delayed_job', after: 'load_config_initializers' do |app|
      app.config.job.validate!
      app.config.job.apply!
    end

    private

    def self.create_delayed_jobs_table(db)
      unless db.table_exists?(:delayed_jobs)
        # See https://github.com/collectiveidea/delayed_job#gory-details
        db.create_table :delayed_jobs, :force => true do |table|
          table.integer  :priority, :default => 0      # Allows some jobs to jump to the front of the queue
          table.integer  :attempts, :default => 0      # Provides for retries, but still fail eventually.
          table.text     :handler                      # YAML-encoded string of the object that will do work
          table.text     :last_error                   # reason for last failure (See Note below)
          table.datetime :run_at                       # When to run. Could be Time.zone.now for immediately, or sometime in the future.
          table.datetime :locked_at                    # Set when a client is working on this object
          table.datetime :failed_at                    # Set when all retries have failed (actually, by default, the record is deleted instead)
          table.string   :locked_by                    # Who is working on this object (if locked)
          table.string   :queue                        # The name of the queue this job is in
          table.timestamps
        end
      end
    end
  end
end
