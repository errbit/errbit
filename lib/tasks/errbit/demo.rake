namespace :errbit do
  desc "Add a demo app & error to your database (for testing)"
  task :demo => :environment do
    require 'factory_girl_rails'
    Dir.glob(File.join(Rails.root,'spec/factories/*.rb')).each {|f| require f }
    app = Factory(:app, :name => "Demo App #{Time.now.strftime("%N")}")
    Factory(:notice, :err => Factory(:err, :app => app))
    puts "=== Created demo app: '#{app.name}', with an example error."
  end
end

