# Deploy Config
# =============
#
# Copy this file to config/deploy.rb and customize it as needed.
# Then run `cap deploy:setup` to set up your server and finally
# `cap deploy` whenever you would like to deploy Errbit. Refer
# to the Readme for more information.

config = YAML.load_file('config/config.yml')['deployment'] || {}

require 'bundler/capistrano'

set :application, "errbit"
set :repository,  config['repository'] || "http://github.com/errbit/errbit.git"

role :web, config['hosts']['web'] || "errbit.example.com"
role :app, config['hosts']['app'] || "errbit.example.com"
role :db,  config['hosts']['db']  || "errbit.example.com", :primary => true

set :user, config['user'] || :deploy
set :use_sudo, false
if config.has_key?('ssh_key')
  set :ssh_options,      { :forward_agent => true, :keys => [ config['ssh_key'] ] }
else
  set :ssh_options,      { :forward_agent => true }
end
default_run_options[:pty] = true

set :deploy_to, config['deploy_to'] || "/var/www/apps/#{application}"
set :deploy_via, :remote_cache
set :copy_cache, true
set :copy_exclude, [".git"]
set :copy_compression, :bz2

set :scm, :git
set :scm_verbose, true
set(:current_branch) { `git branch`.match(/\* (\S+)\s/m)[1] || raise("Couldn't determine current branch") }
set :branch, defer { current_branch }

after 'deploy:update_code', 'errbit:symlink_configs'

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

namespace :errbit do
  task :setup_configs do
    shared_configs = File.join(shared_path,'config')
    run "mkdir -p #{shared_configs}"
    run "if [ ! -f #{shared_configs}/config.yml ]; then cp #{latest_release}/config/config.example.yml #{shared_configs}/config.yml; fi"
    run "if [ ! -f #{shared_configs}/mongoid.yml ]; then cp #{latest_release}/config/mongoid.example.yml #{shared_configs}/mongoid.yml; fi"
  end

  task :symlink_configs do
    errbit.setup_configs
    shared_configs = File.join(shared_path,'config')
    release_configs = File.join(release_path,'config')
    run("ln -nfs #{shared_configs}/config.yml #{release_configs}/config.yml")
    run("ln -nfs #{shared_configs}/mongoid.yml #{release_configs}/mongoid.yml")
  end
end

namespace :db do
  desc "Create the indexes defined on your mongoid models"
  task :create_mongoid_indexes do
    run "cd #{current_path} && bundle exec rake db:mongoid:create_indexes"
  end
end

