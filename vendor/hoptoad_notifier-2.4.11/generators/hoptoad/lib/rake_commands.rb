Rails::Generator::Commands::Create.class_eval do
  def rake(cmd, opts = {})
    logger.rake "rake #{cmd}"
    unless system("rake #{cmd}")
      logger.rake "#{cmd} failed. Rolling back"      
      command(:destroy).invoke!
    end
  end
end

Rails::Generator::Commands::Destroy.class_eval do
  def rake(cmd, opts = {})
    unless opts[:generate_only]
      logger.rake "rake #{cmd}"
      system "rake #{cmd}"
    end
  end
end

Rails::Generator::Commands::List.class_eval do
  def rake(cmd, opts = {})
    logger.rake "rake #{cmd}"
  end
end
