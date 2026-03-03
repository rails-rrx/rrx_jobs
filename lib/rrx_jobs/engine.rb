require 'rails'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/railtie'
require 'active_job/railtie'
require 'active_model/railtie'
require 'solid_queue'

# Register custom ActiveModel attribute types used by RrxJobs configuration objects.
# These were previously provided by didja_rails/types.
ActiveModel::Type.register(:symbol) do
  Class.new(ActiveModel::Type::Value) do
    def cast(value)
      value&.to_sym
    end
  end.new
end

ActiveModel::Type.register(:duration) do
  Class.new(ActiveModel::Type::Value) do
    # Cast accepts an ActiveSupport::Duration or an integer (seconds).
    def cast(value)
      return value if value.is_a?(ActiveSupport::Duration)
      return value.seconds if value.is_a?(Integer)

      value
    end
  end.new
end

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
      # Only validate if workers/queues have been configured — the dummy test app
      # boots without any job configuration and should not raise.
      job = app.config.job
      if job.workers || job.queues
        job.validate!
        job.apply!(app)
      end
    end
  end
end
