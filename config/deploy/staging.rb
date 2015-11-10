set :stage, :staging
set :rails_env, :staging
set :environment, :staging
set :keep_releases, 1
set :log_rotate, 3

set :branch, :staging
set :assets_roles, [:web, :app] # Defaults to [:web]
set :normalize_asset_timestamps, %{public/javascripts}

(1..3).each { |i| server "lb#{i}.mst-stg.3bagels.com", user: 'abb_bb', roles: %w{app}, port: 65321 }