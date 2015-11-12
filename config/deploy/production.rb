set :stage, :production
set :rails_env, :production
set :environment, :production

set :branch, :production
set :assets_roles, [:web, :app] # Defaults to [:web]
set :normalize_asset_timestamps, %{public/javascripts}

(1..3).each { |i| server "lb#{i}.mst.3bagels.com", user: 'abb_bb', roles: %w{app}, port: 65321 }