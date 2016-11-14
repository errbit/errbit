# Deploy Config
# =============
#
# Copy this file to config/deploy.rb and customize it as needed.
# Then run `cap errbit:setup` to set up your server and finally
# `cap deploy` whenever you would like to deploy Errbit. Refer
# to ./docs/deployment/capistrano.md for more info

# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'errbit'
set :repo_url, 'https://github.com/errbit/errbit.git'
set :branch, ENV['branch'] || 'master'
set :deploy_to, '/var/www/apps/errbit'
set :keep_releases, 5

set :pty, true
set :ssh_options, forward_agent: true

set :linked_files, fetch(:linked_files, []) + %w(
  .env
  config/newrelic.yml
  config/puma.rb
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
  desc "Set up config files (first time setup)"
  task :setup do
    on roles(:app) do
      execute "mkdir -p #{shared_path}/config"
      execute "mkdir -p #{shared_path}/tmp/pids"
      execute "touch #{shared_path}/.env"

      {
        'config/newrelic.example.yml' => 'config/newrelic.yml'
      }.each do |src, target|
        unless test("[ -f #{shared_path}/#{target} ]")
          upload! src, "#{shared_path}/#{target}"
        end
      end

      invoke 'puma:config'
    end
  end
end

namespace :db do
  desc "Create and set up the mongo db"
  task :setup do
    on roles(:db) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'errbit:bootstrap'
        end
      end
    end
  end
end

set :puma_conf, "#{shared_path}/config/puma.rb"
set :puma_bind, 'tcp://0.0.0.0:8080'
