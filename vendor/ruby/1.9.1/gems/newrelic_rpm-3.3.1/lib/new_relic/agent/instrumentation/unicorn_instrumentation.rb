DependencyDetection.defer do
  @name = :unicorn

  depends_on do
    defined?(::Unicorn) && defined?(::Unicorn::HttpServer)
  end
  
  executes do
    NewRelic::Agent.logger.debug 'Installing Unicorn instrumentation'
  end
  
  executes do
    Unicorn::HttpServer.class_eval do
      old_worker_loop = instance_method(:worker_loop)
      define_method(:worker_loop) do | worker |
        NewRelic::Agent.after_fork(:force_reconnect => true)
        old_worker_loop.bind(self).call(worker)
      end
    end
  end
end
