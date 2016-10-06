module AirbrakeApi
  module V3
    class NoticeParser
      class ParamsError < StandardError; end

      attr_reader :params, :error

      def initialize(params)
        @params = params || {}
      end

      def attributes
        {
          error_class:        error['type'],
          message:            error['message'],
          backtrace:          backtrace,
          request:            request,
          server_environment: server_environment,
          api_key:            params['key'].present? ? params['key'] : params['project_id'],
          notifier:           context['notifier'] || params['notifier'],
          user_attributes:    user_attributes
        }
      end

      def report
        ErrorReport.new(attributes)
      end

    private

      def error
        fail AirbrakeApi::ParamsError unless params.key?('errors') && params['errors'].any?
        @error ||= params['errors'].first
      end

      def backtrace
        (error['backtrace'] || []).map do |backtrace_line|
          {
            method: backtrace_line['function'],
            file:   backtrace_line['file'],
            number: backtrace_line['line'],
            column: backtrace_line['column']
          }
        end
      end

      def server_environment
        {
          'environment-name' => context['environment'],
          'hostname'         => hostname,
          'project-root'     => context['rootDirectory'],
          'app-version'      => context['version']
        }
      end

      def request
        environment = (params['environment'] || {}).merge(
          'HTTP_USER_AGENT' => context['userAgent']
        )

        {
          'cgi-data'  => environment,
          'session'   => params['session'],
          'params'    => params['params'],
          'url'       => url,
          'component' => context['component'],
          'action'    => context['action']
        }
      end

      def user_attributes
        return context['user'] if context['user']

        {
          'id'       => context['userId'],
          'name'     => context['userName'],
          'email'    => context['userEmail'],
          'username' => context['userUsername']
        }.compact
      end

      def url
        context['url']
      end

      def hostname
        context['hostname'] || URI.parse(url).hostname
      rescue URI::InvalidURIError
        ''
      end

      def context
        @context = params['context'] || {}
      end
    end
  end
end
