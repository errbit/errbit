# Defines deploy:notify_hoptoad which will send information about the deploy to Hoptoad.

Capistrano::Configuration.instance(:must_exist).load do
  after "deploy",            "deploy:notify_hoptoad"
  after "deploy:migrations", "deploy:notify_hoptoad"

  namespace :deploy do
    desc "Notify Hoptoad of the deployment"
    task :notify_hoptoad, :except => { :no_release => true } do
      rails_env = fetch(:hoptoad_env, fetch(:rails_env, "production"))
      local_user = ENV['USER'] || ENV['USERNAME']
      executable = RUBY_PLATFORM.downcase.include?('mswin') ? fetch(:rake, 'rake.bat') : fetch(:rake, 'rake')
      notify_command = "#{executable} hoptoad:deploy TO=#{rails_env} REVISION=#{current_revision} REPO=#{repository} USER=#{local_user}"
      notify_command << " DRY_RUN=true" if dry_run
      notify_command << " API_KEY=#{ENV['API_KEY']}" if ENV['API_KEY']
      puts "Notifying Hoptoad of Deploy (#{notify_command})"
      `#{notify_command}`
      puts "Hoptoad Notification Complete."
    end
  end
end
