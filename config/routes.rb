Errbit::Application.routes.draw do
  
  # Hoptoad Notifier Routes
  match '/notifier_api/v2/notices' => 'notices#create'
  match '/deploys.txt' => 'deploys#create'
  
  resources :errs,    :only => [:index] do
    collection do
      get :all
    end
  end
  resources :notices, :only => [:show]
  resources :deploys, :only => [:show]
  
  resources :projects do
    resources :errs do
      resources :notices
      member do
        put :resolve
      end
    end
  end
  
  root :to => 'projects#index'
  
end
