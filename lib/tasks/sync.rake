namespace :sync do

  desc 'Synchronizes local database with production'
  task :local => :backup do
    file_name = "mongodump.#{Time.now.strftime('%Y%m%d')}"
    ENV['MONGOLAB_URI'] = 'heroku_app8273235'
    app_name = "#{ENV['MONGOLAB_URI']}"
    cmd = "mongorestore -v -h localhost " \
      "--port 27017 " \
      "--db finalcloud_erribit_development " \
      "--drop tmp/#{file_name}/#{app_name}"
    system cmd
  end

  task :reload do |t, args|
    file_name = "mongodump.#{Time.now.strftime('%Y%m%d')}"
    ENV['MONGOLAB_URI'] = 'heroku_app8273235'
    app_name = "#{ENV['MONGOLAB_URI']}"
    cmd = "mongorestore -v -h localhost " \
      "--port 27017 " \
      "--db finalcloud_erribit_development " \
      "--drop tmp/#{file_name}/#{app_name}"
    system cmd
  end

  task :backup do |t, args|
    ENV['MONGOHQ_URL']      = 'ds037977.mongolab.com:37977'
    ENV['MONGOLAB_URI']     = 'heroku_app8273235'
    ENV['MONGOHQ_USERNAME'] = 'heroku_app8273235_A'
    ENV['MONGOHQ_PASSWORD'] = 'qkIloLhbqProzmPrmZhNmmMwtWRDvBwf'

    file_name = "mongodump.#{Time.now.strftime('%Y%m%d')}"
    cmd = "mongodump -h #{ENV['MONGOHQ_URL']} " \
      "-d #{ENV['MONGOLAB_URI']} -u #{ENV['MONGOHQ_USERNAME']} " \
      "-p #{ENV['MONGOHQ_PASSWORD']} " \
      "-o tmp/#{file_name}"
    system cmd
  end

end
