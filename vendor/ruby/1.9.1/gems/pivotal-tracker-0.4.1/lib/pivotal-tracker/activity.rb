module PivotalTracker
  class Activity
    include HappyMapper
    class << self
      def all(project=nil, options={})
        params = self.encode_options(options)
        if project
          parse(Client.connection["/projects/#{project.id}/activities#{params}"].get)
        else
          parse(Client.connection["/activities#{params}"].get)
        end
      end

      protected

        def encode_options(options)
          return nil if !options.is_a?(Hash) || options.empty?

          options_string = []
          options_string << "limit=#{options.delete(:limit)}" if options[:limit]
          options_string << "newer_than_version=#{options.delete(:newer_than_version)}" if options[:newer_than_version]

          if options[:occurred_since]
            options_string << "occurred_since_date=\"#{options[:occurred_since].utc}\""
          elsif options[:occurred_since_date]
            options_string << "occurred_since_date=#{URI.escape options[:occurred_since_date].strftime("%Y/%m/%d %H:%M:%S %Z")}"
          end

          return "?#{options_string.join('&')}"
        end

    end

    element :id, Integer
    element :version, Integer
    element :event_type, String
    element :occurred_at, DateTime
    element :author, String
    element :project_id, Integer
    element :description, String

    has_many :stories, Story

  end
end
