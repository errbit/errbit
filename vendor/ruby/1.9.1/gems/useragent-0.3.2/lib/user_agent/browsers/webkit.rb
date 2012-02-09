class UserAgent
  module Browsers
    module Webkit
      def self.extend?(agent)
        agent.detect { |useragent| useragent.product == 'AppleWebKit' }
      end

      def webkit?
        true
      end

      def browser
        if os =~ /Android/
          'Android'
        elsif detect_product('Chrome')
          'Chrome'
        elsif platform == 'webOS' || platform == 'BlackBerry'  || platform == 'Symbian'
          platform 
        else
          'Safari'
        end
      end

      def build
        webkit.version
      end

      BuildVersions = {
        "85.7" => "1.0",
        "85.8.5" => "1.0.3",
        "85.8.2" => "1.0.3",
        "124" => "1.2",
        "125.2" => "1.2.2",
        "125.4" => "1.2.3",
        "125.5.5" => "1.2.4",
        "125.5.6" => "1.2.4",
        "125.5.7" => "1.2.4",
        "312.1.1" => "1.3",
        "312.1" => "1.3",
        "312.5" => "1.3.1",
        "312.5.1" => "1.3.1",
        "312.5.2" => "1.3.1",
        "312.8" => "1.3.2",
        "312.8.1" => "1.3.2",
        "412" => "2.0",
        "412.6" => "2.0",
        "412.6.2" => "2.0",
        "412.7" => "2.0.1",
        "416.11" => "2.0.2",
        "416.12" => "2.0.2",
        "417.9" => "2.0.3",
        "418" => "2.0.3",
        "418.8" => "2.0.4",
        "418.9" => "2.0.4",
        "418.9.1" => "2.0.4",
        "419" => "2.0.4",
        "425.13" => "2.2"
      }.freeze

      # Prior to Safari 3, the user agent did not include a version number
      def version
        str = if os =~ /CPU (?:iPhone |iPod )?OS ([\d_]+) like Mac OS X/
          $1.gsub(/_/, '.')
        elsif product = detect_product('Version')
          product.version
        elsif browser == 'Chrome'
          chrome.version
        else
          BuildVersions[build.to_s]
        end

        Version.new(str) if str
      end
      
      def application
         apps = self.reject{|agent| agent.comment.nil? || agent.comment.empty?} 
         apps.first 
      end

      def platform                                                                                                       
        if application.comment[0] =~ /Symbian/
        'Symbian'             
        elsif application.comment[0] =~ /webOS/
          'webOS'
        else
          application.comment[0]
        end
      end

      def webkit
        detect { |useragent| useragent.product == "AppleWebKit" }
      end

      def security
        Security[application.comment[1]]
      end

      def os
        if platform == 'webOS'
          "Palm #{last.product} #{last.version}"
        elsif platform == 'Symbian'
          application.comment[0]
        else
          OperatingSystems.normalize_os(application.comment[2])
        end
      end

      def localization
        # TODO: Ensure that this is common to all webOS UserAgent
        if platform == 'webOS'
          application.comment[2]
        else
          application.comment[3]
        end
      end

    end
  end
end
