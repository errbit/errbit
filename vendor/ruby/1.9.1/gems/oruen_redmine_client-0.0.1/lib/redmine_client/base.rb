module RedmineClient
  class Base < ActiveResource::Base
  
    class << self
      def configure(&block)
        instance_eval &block
      end

      # Get your API key at "My account" page
      def token= val
        if val
          (descendants + [self]).each do |resource|
            resource.headers['X-Redmine-API-Key'] = val
          end
        end
      end
    end
  end
end

