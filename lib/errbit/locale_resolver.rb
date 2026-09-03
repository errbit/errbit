# frozen_string_literal: true

require "http_accept_language"

module Errbit
  module LocaleResolver
    module_function

    def browser_locale(header)
      preferred = HttpAcceptLanguage::Parser.new(header.to_s).user_preferred_languages
      excluded = header.to_s.scan(/(?:\A|,)\s*([^,;\s]+)[^,]*;\s*q\s*=\s*0(?:\.0*)?\s*(?:,|\z)/i).flatten.map { |tag| normalize(tag) }

      preferred.filter_map do |language|
        next if language == "*"

        candidate_locale(language, excluded: excluded)
      end.first
    rescue ArgumentError, TypeError
      nil
    end

    def candidate_locale(language, excluded: [])
      requested = normalize(language)
      return if requested.empty?

      catalogs = Errbit::Locales.identifiers.reject { |identifier| identifier == "en" }
      exact = catalogs.find { |identifier| identifier == requested }
      return exact unless exact.nil? || excluded_language?(exact, excluded)

      language_only = requested.split("-").first
      regional = catalogs
        .select { |identifier| identifier.split("-").first == language_only }
        .reject { |identifier| excluded_language?(identifier, excluded) }
        .sort
      return regional.first if regional.any?

      "en" if language_only == "en" && !excluded_language?("en", excluded)
    end

    def locale_for(request)
      browser_locale(request.get_header("HTTP_ACCEPT_LANGUAGE")) || I18n.default_locale.to_s
    end

    def normalize(locale)
      Errbit::Locales.normalize(locale)
    end

    def excluded_language?(candidate, excluded)
      excluded.any? { |language| candidate == language || candidate.start_with?("#{language}-") }
    end
  end
end
