# Used for running Raindrops::Watcher, which requires a multi-threaded
# Rack server capable of streaming a response.  Threads must be used,
# so Zbatery is recommended: http://zbatery.bogomip.org/
Rainbows! do
  use :ThreadSpawn
end
log_dir = "/var/log/zbatery"
if File.writable?(log_dir) && File.directory?(log_dir)
  stderr_path "#{log_dir}/raindrops-demo.stderr.log"
  stdout_path "#{log_dir}/raindrops-demo.stdout.log"
  listen "/tmp/.raindrops"
  pid "/tmp/.raindrops.pid"
end
