module EmailSpec
  module MailerDeliveries
    def all_emails
      deliveries
    end

    def last_email_sent
      deliveries.last || raise("No email has been sent!")
    end

    def reset_mailer
      if defined?(ActionMailer) && ActionMailer::Base.delivery_method == :cache
        mailer.clear_cache
      else
        deliveries.clear
      end
    end

    def mailbox_for(address)
      deliveries.select { |email|
        (email.to && email.to.include?(address)) ||
        (email.bcc && email.bcc.include?(address)) ||
        (email.cc && email.cc.include?(address)) }
    end

    protected

    def deliveries
      if ActionMailer::Base.delivery_method == :cache
        mailer.cached_deliveries
      else
        mailer.deliveries
      end
    end
  end

  module ARMailerDeliveries
    def all_emails
      Email.all.map{ |email| parse_to_mail(email) }
    end

    def last_email_sent
      if email = Email.last
        Mail.read(email.mail)
      else
        raise("No email has been sent!")
      end
    end

    def reset_mailer
      Email.delete_all
    end

    def mailbox_for(address)
      Email.all.select { |email|
        (email.to && email.to.include?(address)) ||
        (email.bcc && email.bcc.include?(address)) ||
        (email.cc && email.cc.include?(address)) }.map{ |email| parse_to_mail(email) }
    end

    def parse_to_mail(email)
      Mail.read(email.mail)
    end
  end

  if defined?(Pony)
    module ::Pony
      def self.deliveries
        @deliveries ||= []
      end

      def self.mail(options)
        deliveries << build_mail(options)
      end
    end
  end

  module Deliveries
    if defined?(Pony)
      def deliveries; Pony::deliveries ; end
      include EmailSpec::MailerDeliveries
    elsif ActionMailer::Base.delivery_method == :activerecord
      include EmailSpec::ARMailerDeliveries
    else
      def mailer; ActionMailer::Base; end
      include EmailSpec::MailerDeliveries
    end
    include EmailSpec::BackgroundProcesses::Compatibility
  end
end

