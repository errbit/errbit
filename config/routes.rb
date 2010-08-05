Hypnotoad::Application.routes.draw do
  
  # Hoptoad Notifier Routes
  match '/notifier_api/v2/notices' => 'notices#create'
  match '/deploys.txt' => 'deploys#create'
  
  resources :notices, :only => [:show]
  resources :deploys, :only => [:show]
  
  resources :projects do
    resources :errs do
      resources :notices
    end
  end
  
  root :to => 'projects#index'
  
end
