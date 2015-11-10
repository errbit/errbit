lock '3.4.0'

set :application, 'abb_bb'
set :repo_url, 'git@github.com:AllBestBets/errbit.git'

set :user, 'abb_bb'
set :deploy_to, -> { "/home/#{fetch(:user)}" }
set :keep_releases, 20
set :scm, :git
set :rvm_ruby_version, 'ruby-2.2.3@abb_web'

set :format, :pretty
set :log_level, :debug
set :pty, true

set :linked_dirs, %w{log pids tmp assets_manifest_backup}
set :linked_files, %w{config/database.yml config/secrets.yml config/mongoid.yml config/newrelic.yml}

set :tmp_dir, -> { "#{fetch(:deploy_to)}/tmp" }
set :ssh_options, {user: fetch(:user), keys: %w(~/.ssh/id_rsa), forward_agent: true}

set :pid_file, -> { "#{fetch(:deploy_to)}/current/tmp/pids/errbit_unicorn.pid" }
set :log_rotate, 14

namespace :rvm do
  task :install_env do
    on roles(:all) do
      unless test('[ -w ~/.rvm/ ]')
        execute <<-EOBLOCK
          gpg2 --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
          \\curl -sSL https://get.rvm.io | bash -s stable
          source ~/.rvm/scripts/rvm
          rvm get stable --auto
          echo rvm_install_on_use_flag=1 >> ~/.rvmrc
          echo rvm_gemset_create_on_use_flag=1 >> ~/.rvmrc
          echo rvm_autoupdate_flag=2 >> ~/.rvmrc
        EOBLOCK
      end

      execute <<-EOBLOCK
        source ~/.rvm/scripts/rvm
        rvm use #{fetch(:rvm_ruby_version)} --default
        gem install --no-rdoc --no-ri bundler
        mkdir -p shared
        mkdir -p shared/tmp
        mkdir -p shared/tmp/pids
      EOBLOCK

      # mkdir -p shared/assets
      # mkdir -p shared/assets_manifest_backup
    end
  end

  before :hook, :install_env

  task :remove_env do
    on roles(:all) do
      execute 'rm -rf .rvm .rvmrc'
    end
  end
end

namespace :deploy do

  # namespace :assets do
  #   task :precompile do
  #     on release_roles(fetch(:assets_roles)) do
  #       within release_path do
  #         with rails_env: fetch(:rails_env) do
  #           execute :rake, 'assets:precompile'
  #           execute :rake, 'assets:nondigested'
  #           execute :rake, 'assets:sync'
  #         end
  #       end
  #     end
  #   end
  # end

  # task :reinstall_mysql2 do
  #   on roles(:all) do
  #     within release_path do
  #       execute :gem, :uninstall, :mysql2 rescue nil
  #       execute :bundle, :install
  #     end
  #   end
  # end

  # task :system_assets do
  #   on roles(:all) do
  #     within release_path do
  #       execute "rm -rf #{fetch(:deploy_to)}/current/public/assets"
  #       execute "ln -s #{fetch(:deploy_to)}/shared/assets #{release_path}/public/"
  #     end
  #   end
  # end
  # before 'deploy:assets:precompile', 'deploy:system_assets'

  # task :system_symlink do
  #   on roles(:all) do
  #     execute "rm -rf #{fetch(:deploy_to)}/current/public/system"
  #     execute "ln -s #{fetch(:deploy_to)}/shared/system #{fetch(:deploy_to)}/current/public/"
  #   end
  # end
  # after 'deploy:symlink:release', 'deploy:system_symlink'

  task :upload_config_files do
    on roles(:app) do |host|
      upload!("../.abb_configs/#{fetch(:user)}/#{host.to_s}/.", "#{fetch(:deploy_to)}/shared/config", recursive: true) if File.directory?('../.abb_configs')
    end
  end
  before 'deploy:check:linked_files', 'deploy:upload_config_files'

  task :start do
    on roles(:app) do
      within release_path do
        execute "cd #{release_path} && ~/.rvm/bin/rvm #{fetch(:rvm_ruby_version)} do bundle exec unicorn -c config/unicorn.rb -E #{fetch(:environment)} -D"
      end
    end
  end

  task :stop do
    on roles(:app) do
      within release_path do
        execute "if [ -f #{fetch(:pid_file)} ]; then kill -QUIT `cat #{fetch(:pid_file)}`; fi"
      end
    end
  end

  task :force_stop do
    on roles(:app) do
      execute "kill -QUIT `cat #{fetch(:pid_file)}`" rescue nil
      execute "kill -9 `cat #{fetch(:pid_file)}`" rescue nil
      execute "ps aux | grep unicorn.rb  | awk '{print $2}' | xargs kill -9"
      execute "ps aux | grep appsignal  | awk '{print $2}' | xargs kill -9"
      execute "rm #{fetch(:pid_file)}" rescue nil
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      with rails_env: fetch(:environment) do
        within release_path do
          begin
            execute "if [ -f #{fetch(:pid_file)} ]; then kill -USR2 `cat #{fetch(:pid_file)}`; else cd #{release_path}; ~/.rvm/bin/rvm #{fetch(:rvm_ruby_version)} do bundle exec unicorn -c config/unicorn.rb -E #{fetch(:environment)} -D; fi"
          rescue => ex
            puts ex.message
          end
        end
      end
    end
  end

  task(:force_restart) {}
  before :force_restart, 'deploy:force_stop'
  after :force_restart, 'deploy:start'

  after 'deploy:finishing', 'deploy:cleanup'
  before 'deploy:finishing', 'deploy:restart'

  desc 'Update restart.sh startup.sh shutdown.sh scripts'
  task :update_bash_scripts do
    on roles(:app) do
      execute <<-CMD
        touch startup.sh; chmod +x startup.sh
        echo \"#!/bin/bash\" > ~/startup.sh
        echo \"cd #{release_path} \" >> ~/startup.sh
        echo \"exec ~/.rvm/bin/rvm #{fetch(:rvm_ruby_version)} do bundle exec unicornherder -u unicorn -p #{fetch(:pid_file)} -- -c config/unicorn.rb -E #{fetch(:environment)} \" >> ~/startup.sh
      CMD

      execute("find #{release_path}/log/ -mtime +#{fetch(:log_rotate)} -type f -delete")
    end
  end
  after 'deploy:finishing', 'deploy:update_bash_scripts'
  after 'deploy:updated', 'newrelic:notice_deployment'
end
require 'appsignal/capistrano'