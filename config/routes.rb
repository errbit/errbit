# frozen_string_literal: true

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks"}

  # Hoptoad Notifier Routes
  match "/notifier_api/v2/notices" => "notices#create", :via => [:get, :post]
  get "/locate/:id" => "notices#locate", :as => :locate
  get "/notices/:id" => "notices#show_by_id", :as => :show_notice_by_id

  resources :notices, only: :show

  resources :users do
    resource :unlink_github, only: :update

    resource :unlink_google, only: :update
  end

  resources :site_config, only: :index do
    collection do
      put :update
    end
  end

  resources :problems, only: :index do
    collection do
      post :destroy_several
      post :resolve_several
      post :unresolve_several
      post :merge_several
      post :unmerge_several
      get :search
    end
  end

  resources :apps do
    resources :problems do
      resources :notices

      resources :comments, only: [:create, :destroy]

      collection do
        post :destroy_all
      end

      member do
        get :xhr_sparkline
        put :resolve
        put :unresolve
        post :create_issue
        post :close_issue
        delete :unlink_issue
      end
    end

    resources :watchers, only: [:destroy, :update]

    member do
      post :regenerate_api_key
    end

    collection do
      get :search
    end
  end

  get "problems/:id" => "problems#show_by_id"

  get "health/api-key-tester" => "health#api_key_tester"

  namespace :api do
    namespace :v1 do
      resources :problems, only: [:index, :show], defaults: {format: "json"} do
        resources :comments, only: [:index, :create], defaults: {format: "json"}
      end

      resources :notices, only: :index, defaults: {format: "json"}

      resources :stats, only: [], defaults: {format: "json"} do
        collection do
          get :app
        end
      end
    end
  end

  post "/api/v3/projects/:project_id/create-notice" => "api/v3/notices#create"

  match "/api/v3/projects/:project_id/notices" => "api/v3/notices#create", :via => [:post, :options]

  root to: "apps#index"
end
