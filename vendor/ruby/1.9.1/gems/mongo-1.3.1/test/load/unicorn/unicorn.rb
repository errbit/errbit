# set path to app that will be used to configure unicorn, 
# # note the trailing slash in this example
@dir = "/home/kyle/work/10gen/ruby-driver/test/load/"

worker_processes 10
working_directory @dir

preload_app true

timeout 30

# Specify path to socket unicorn listens to,
# we will use this in our nginx.conf later
listen "#{@dir}tmp/sockets/unicorn.sock", :backlog => 64

# Set process id path
pid "#{@dir}tmp/pids/unicorn.pid"

# # Set log file paths
stderr_path "#{@dir}log/unicorn.stderr.log"
stdout_path "#{@dir}log/unicorn.stdout.log" 

# NOTE: You need this when using forking web servers!
after_fork do |server, worker|
  $con.close if $con
  $con = Mongo::Connection.new
  $db = $con['foo']
  STDERR << "FORKED #{server} #{worker}"
end
