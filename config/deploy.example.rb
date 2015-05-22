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
  config/unicorn.rb
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
  desc "Setup config files (first time setup)"
  task :setup do
    on roles(:app) do
      execute "mkdir -p #{shared_path}/config"
      execute "mkdir -p #{shared_path}/tmp/pids"
      execute "touch #{shared_path}/.env"

      {
        'config/newrelic.example.yml' => 'config/newrelic.yml',
        'config/unicorn.default.rb' => 'config/unicorn.rb',
      }.each do |src, target|
        unless test("[ -f #{shared_path}/#{target} ]")
          upload! src, "#{shared_path}/#{target}"
        end
      end
    end
  end
end

namespace :db do
  desc "Create and setup the mongo db"
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

set :unicorn_pidfile, "#{fetch(:deploy_to)}/shared/tmp/pids/unicorn.pid"
set :unicorn_pid, "`cat #{fetch(:unicorn_pidfile)}`"

namespace :unicorn do
  desc 'Start unicorn'
  task :start do
    on roles(:app) do
      within current_path do
        if test " [ -s #{fetch(:unicorn_pidfile)} ] "
          warn "Unicorn is already running."
        else
          with "UNICORN_PID" => fetch(:unicorn_pidfile) do
            execute :bundle, :exec, :unicorn, "-D -c ./config/unicorn.rb"
          end
        end
      end
    end
  end

  desc 'Reload unicorn'
  task :reload do
    on roles(:app) do
      execute :kill, "-HUP", fetch(:unicorn_pid)
    end
  end

  desc 'Stop unicorn'
  task :stop do
    on roles(:app) do
      if test " [ -s #{fetch(:unicorn_pidfile)} ] "
        execute :kill, "-QUIT", fetch(:unicorn_pid)
      else
        warn "Unicorn is not running."
      end
    end
  end

  desc 'Reexecute unicorn'
  task :reexec do
    on roles(:app) do
      execute :kill, "-USR2", fetch(:unicorn_pid)
    end
  end
end
