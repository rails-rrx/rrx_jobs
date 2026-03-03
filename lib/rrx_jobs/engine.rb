require 'rails'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/railtie'
require 'active_job/railtie'
require 'active_model/railtie'
require 'solid_queue'
require_relative 'configuration/jobs'
require 'jbuilder'

module RrxJobs
  class Engine < Rails::Engine
    railtie_name 'rrx_jobs'
    isolate_namespace RrxJobs

    config.job = Configuration::Jobs.new
    config.active_job.queue_adapter = :solid_queue

    rake_tasks do
      Dir[File.expand_path('../../lib/tasks/*.rake', __dir__)].each { |p| load p }
    end

    initializer 'rrx_jobs.controller_extensions' do
      ActiveSupport.on_load(:action_controller) do
        require_relative 'controller_extensions'
        extend RrxJobs::ControllerExtensions
      end
    end

    initializer 'rrx_jobs.solid_queue', after: 'load_config_initializers' do |app|
      app.config.job.validate!
      app.config.job.apply!(app)
    end
  end
end
