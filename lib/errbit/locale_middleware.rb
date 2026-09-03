# frozen_string_literal: true

require_relative "locale_resolver"

module Errbit
  class LocaleMiddleware
    API_PATHS = %r{\A/(?:api|notifier_api)(?:/|\z)}

    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      api_request = request.path.match?(API_PATHS)
      locale = api_request ? I18n.default_locale : LocaleResolver.locale_for(request)

      response = I18n.with_locale(locale) { @app.call(env) }
      return response if api_request

      response[1]["Vary"] = [response[1]["Vary"], "Accept-Language"].compact.join(", ")
      response
    end
  end
end
