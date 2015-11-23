if ENV['USE_UNICORN_WORKER_KILLER']
  require 'unicorn/worker_killer'
  max_request_min =  ENV['KILL_ON_REQUEST_COUNT_MIN'].to_i || 3072
  max_request_max =  ENV['KILL_ON_REQUEST_COUNT_MAX'].to_i || 4096
  use Unicorn::WorkerKiller::MaxRequests, max_request_min, max_request_max
  oom_min = ((ENV['KILL_ON_RSS_MIN'].to_i || 250) * (1024**2))
  oom_max = ((ENV['KILL_ON_RSS_MAX'].to_i || 300) * (1024**2))
  use Unicorn::WorkerKiller::Oom, oom_min, oom_max
end

# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)
use Rack::Deflater
run Rails.application
