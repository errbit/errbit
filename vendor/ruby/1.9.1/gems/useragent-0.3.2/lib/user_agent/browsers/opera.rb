class UserAgent
  module Browsers
    module Opera
      def self.extend?(agent)
        agent.application && agent.application.product == "Opera"
      end

      def platform
        if application.comment[0] =~ /Windows/
          "Windows"
        else
          application.comment[0]
        end
      end

      def security
        if platform == "Macintosh"
          Security[application.comment[2]]
        else
          Security[application.comment[1]]
        end
      end

      def os
        if application.comment[0] =~ /Windows/
          OperatingSystems.normalize_os(application.comment[0])
        else
          application.comment[1]
        end
      end

      def localization
        if platform == "Macintosh"
          application.comment[3]
        else
          application.comment[2]
        end
      end
    end
  end
end
