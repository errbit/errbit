# Deploy Config
# =============
#
# Copy this file to config/deploy.rb and customize it as needed.
# Then run `cap deploy:setup` to set up your server and finally
# `cap deploy` whenever you would like to deploy Errbit. Refer
# to the Readme for more information.

# config valid only for current version of Capistrano
lock '3.3.5'

set :application, 'errbit'
set :repo_url, 'https://github.com/errbit/errbit.git'
set :branch, ENV['branch'] || 'master'
set :deploy_to, '/var/www/apps/errbit'
set :keep_releases, 5

set :pty, true
set :ssh_options, forward_agent: true

set :linked_files, fetch(:linked_files, []) + %w(
  .env
  config/config.yml
  config/mongoid.yml
  config/newrelic.yml
)

set :linked_dirs, fetch(:linked_dirs, []) + %w(
  log
  tmp/cache tmp/pids tmp/sockets
  vendor/bundle
)

# check out capistrano-rbenv documentation
# set :rbenv_type, :system
# set :rbenv_path, '/usr/local/rbenv'
# set :rbenv_ruby, File.read(File.expand_path('../../.ruby-version', __FILE__)).strip
# set :rbenv_roles, :all

namespace :errbit do
  task :setup_configs do
    on roles(:app) do
      execute "mkdir -p #{shared_path}/config"
      {
        'config/config.example.yml' => 'config/config.yml',
        'config/mongoid.example.yml' => 'config/mongoid.yml',
        'config/newrelic.example.yml' => 'config/newrelic.yml'
      }.each do |src, target|
        execute "if [ ! -f #{shared_path}/#{target} ]; then cp #{current_path}/#{src} #{shared_path}/#{target}; fi"
      end
    end
  end
end

namespace :db do
  desc "Create the indexes defined on your mongoid models"
  task :create_mongoid_indexes do
    on roles(:db) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'db:mongoid:create_indexes'
        end
      end
    end
  end
end

set :unicorn_pid, "`cat #{"#{fetch(:deploy_to)}/shared/pids"}/unicorn.pid`"

namespace :unicorn do
  desc 'Reload unicorn'
  task :reload do
    on roles(:app) do
      execute :kill, "-HUP #{fetch(:unicorn_pid)}"
    end
  end

  desc 'Stop unicorn'
  task :stop do
    on roles(:app) do
      execute :kill, "-QUIT #{fetch(:unicorn_pid)}"
    end
  end

  desc 'Reexecute unicorn'
  task :reexec do
    on roles(:app) do
      execute :kill, "-USR2 #{fetch(:unicorn_pid)}"
    end
  end
end
