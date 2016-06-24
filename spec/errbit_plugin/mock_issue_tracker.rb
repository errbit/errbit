module ErrbitPlugin
  class MockIssueTracker < IssueTracker
    def self.label
      'mock'
    end

    def self.note
      'A fake issue tracker to help in testing purpose'
    end

    def self.fields
      {
        foo: { label: 'foo' },
        bar: { label: 'bar' }
      }
    end

    attr_accessor :output

    def initialize(*)
      super
      @output = []
    end

    def configured?
      !errors.any?
    end

    def errors
      errors = []
      errors << [:base, 'foo is required'] unless options[:foo]
      errors << [:base, 'bar is required'] unless options[:bar]
      errors
    end

    def create_issue(title, body, user)
      @output << [title, body, user]
      "http://example.com/mock-errbit"
    end

    def close_issue(url, user)
      @output << [url, user]
      "http://example.com/mock-errbit"
    end

    def url
      ''
    end

    def comments_allowed?
      false
    end
  end
end
