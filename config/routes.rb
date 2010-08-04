Hypnotoad::Application.routes.draw do
  
  # Hoptoad Notifier Routes
  match '/notifier_api/v2/notices' => 'notices#create'
  # match '/deploys.txt' => 'deploys#create'
  
  resources :notices
  resources :errors do
    resources :notices
  end
  
end
