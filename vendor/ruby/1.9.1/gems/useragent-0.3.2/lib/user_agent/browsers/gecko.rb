class UserAgent
  module Browsers
    module Gecko
      def self.extend?(agent)
        agent.application && agent.application.product == "Mozilla"
      end

      GeckoBrowsers = %w(
        Firefox
        Camino
        Iceweasel
        Seamonkey
      ).freeze

      def browser
        GeckoBrowsers.detect { |browser| respond_to?(browser) } || super
      end

      def version
        send(browser).version || super
      end

      def platform
        application.comment[0]
      end

      def security
        Security[application.comment[1]] || :strong
      end

      def os
        i = application.comment[1] == 'U' ? 2 : 1
        OperatingSystems.normalize_os(application.comment[i])
      end

      def localization
        application.comment[3]
      end
    end
  end
end
