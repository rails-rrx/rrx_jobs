# frozen_string_literal: true

RrxJobs::Engine.routes.draw do
  resources :jobs, only: [:index], defaults: {format: 'json'} do
    collection do
      delete '/', action: :reset
      get :stats

      scope path: 'stats' do
        post :report
        get :graph, defaults: {format: 'png'}
      end
    end
  end
end
