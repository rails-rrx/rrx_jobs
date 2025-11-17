# frozen_string_literal: true
require 'jbuilder'
require 'rrx_jobs/job_stats'
require 'rrx_jobs/job_manager'

BaseController = begin
                   require 'rrx_api'
                   RrxApi::Controller
                 rescue Exception
                   require 'action_controller/api'
                   ActionController::API
                 end

module RrxJobs
  class JobsController < BaseController
    GRAPH_EXPIRATION = 30.seconds
    QUEUE_STATES = %w[running pending failed].freeze

    before_action :metrics_required, only: %i[report graph]

    def index
      limit = params[:limit] || 100
      query = case params[:filter]
              when 'pending'
                JobManager.pending
              when 'failed'
                JobManager.failed
              when 'running'
                JobManager.running
              else
                JobManager.all
              end

      query = query.order(
        [
          JobManager.state_order,
          JobManager.queue_order
        ]
      )

      @jobs = query.page(params[:page]).per(limit)
    end

    def stats
      render json: JobStats.stats
    end

    def reset
      JobManager.reset
      render status: 200, json: { message: 'Reset successful' }
    end

    def report
      require 'rrx_jobs/metric_reporter'
      MetricReporter.report!
      head :ok
    end

    def graph
      graph_params = params.permit(:state, :scope, :width, :height).to_h.symbolize_keys
      send_data create_graph_image(**graph_params),
                type: 'image/png',
                disposition: 'inline'
    end

    private

    def job_config
      Rails.application.config.job
    end

    def metrics_required
      head :not_found unless job_config.metrics.enabled?
    end

    def create_graph_image(scope: :all, state: :all, width: 600, height: 400)
      require 'didja_rails/metrics_graph'

      raise ArgumentError, 'Must specify a specific queue/group or state' if scope == :all && state == :all
      raise ArgumentError, 'Invalid state' unless state == :all || QUEUE_STATES.include?(state)
      raise ArgumentError, 'Invalid queue/group' unless scope == :all or job_config.queue_or_group?(scope)

      key = 'jobs/graph/%s/%s/%sx%s' % [scope, state, width, height]

      Rails.cache.fetch(key, expires: GRAPH_EXPIRATION) do
        graph = DidjaRails::MetricsGraph.new stacked: true, env: true

        case
        when scope == :all
          # Show all queues for specific state
          job_config.queues.each do |queue|
            graph.metric job_config.metrics.namespace,
                         state.camelize,
                         label: queue.name,
                         stat: :max,
                         queue: queue.name
          end
        when state == :all
          # Show all states for specific queue
          QUEUE_STATES.each do |queue_state|
            state_name = queue_state.camelize
            graph.metric job_config.metrics.namespace,
                         state_name,
                         label: state_name,
                         stat: :max,
                         queue: scope
          end
        else
          # Show only single state for specific queue/group
          graph.metric job_config.metrics.namespace,
                       state.camelize,
                       stat: :max,
                       queue: scope
        end

        graph.render
      end
    end
  end
end
