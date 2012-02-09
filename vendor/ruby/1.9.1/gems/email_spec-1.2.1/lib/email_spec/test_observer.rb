module EmailSpec
  class TestObserver
    def self.delivered_email(message)
      ActionMailer::Base.deliveries << message
    end
  end
end