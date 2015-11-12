$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..')))

Dir.mkdir('tmp') unless File.exist?('tmp')
Dir.mkdir('tmp/pids') unless File.exist?('tmp/pids')

pid_file = 'tmp/pids/errbit_unicorn.pid'
socket_file= "unix:/tmp/#{ENV['RACK_ENV']}_errbit_unicorn.sock"
log_file = 'log/unicorn.log'
err_log = 'log/unicorn_error.log'
old_pid = pid_file + '.oldbin'

timeout 30
worker_processes(ENV['RACK_ENV'] == 'production' ? 5 : 1)
working_directory(ENV['APP_PATH'] || Dir.pwd)

listen socket_file, backlog: 1024
listen 3400, tcp_nopush: true

pid pid_file
stderr_path err_log
stdout_path log_file

preload_app true
GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

before_exec { |server| ENV['BUNDLE_GEMFILE'] = 'Gemfile' }

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill('QUIT', File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  Redis.current.client.reconnect
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end