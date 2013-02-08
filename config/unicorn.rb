# http://michaelvanrooijen.com/articles/2011/06/01-more-concurrency-on-a-single-heroku-dyno-with-the-new-celadon-cedar-stack/

worker_processes 3 # amount of unicorn workers to spin up
timeout 30         # restarts workers that hang for 30 seconds
preload_app true
working_directory "/var/www/errbit/"

# This is where we specify the socket.
# We will point the upstream Nginx module to this socket later on
listen "/var/www/errbit/tmp/sockets/unicorn.sock", :backlog => 64
listen 3001, :tcp_nopush => true

pid "/var/www/errbit/tmp/pids/unicorn.pid"
# Set the path of the log files inside the log folder of the testapp
stderr_path "/var/www/errbit/log/unicorn.stderr.log"
stdout_path "/var/www/errbit/log/unicorn.stdout.log"
before_fork do |server, worker|
    # This option works in together with preload_app true setting
    defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
    defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end

