Errbit::Application.routes.draw do

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  # Hoptoad Notifier Routes
  match '/notifier_api/v2/notices' => 'notices#create'
  match '/deploys.txt' => 'deploys#create'

  resources :notices,   :only => [:show]
  resources :deploys,   :only => [:show]
  resources :users
  resources :errs,      :only => [:index] do
    collection do
      post :destroy_several
      post :resolve_several
      post :unresolve_several
      post :merge_several
      post :unmerge_several
      get :all
    end
  end

  resources :apps do
    resources :errs do
      resources :notices
      member do
        put :resolve
        put :unresolve
        post :create_issue
        delete :unlink_issue
        post :create_comment
        delete :destroy_comment
      end
    end

    resources :deploys, :only => [:index]
  end

  root :to => 'apps#index'

end

