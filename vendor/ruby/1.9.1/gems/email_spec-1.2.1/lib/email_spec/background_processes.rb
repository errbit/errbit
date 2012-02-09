module EmailSpec
  module BackgroundProcesses
    module DelayedJob
      def all_emails
        work_off_queue
        super
      end

      def last_email_sent
        work_off_queue
        super
      end

      def reset_mailer
        work_off_queue
        super
      end

      def mailbox_for(address)
        work_off_queue
        super
      end

      private

      # Later versions of DelayedJob switch from using Delayed::Job to Delayed::Worker
      # Support both versions for those who haven't upgraded yet
      def work_off_queue
        if Delayed::Worker.instance_methods.detect{|iv| iv.to_s == "work_off" }
          Delayed::Worker.send :public, :work_off
          worker = Delayed::Worker.new(:max_priority => nil, :min_priority => nil, :quiet => true)
          worker.work_off
        else
          Delayed::Job.work_off
        end
      end
    end

    module Compatibility
      if defined?(Delayed) && (defined?(Delayed::Job) || defined?(Delayed::Worker))
        include EmailSpec::BackgroundProcesses::DelayedJob
      end
    end
  end
end
