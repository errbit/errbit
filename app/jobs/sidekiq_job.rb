class SidekiqJob
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def self.perform_later *args
    perform_async *args
  end

end
