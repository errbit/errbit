# frozen_string_literal: true

require "yaml"

module Errbit
  module Locales
    Catalog = Data.define(:identifier, :name)

    class CatalogError < StandardError; end

    module_function

    def selectable
      @selectable ||= load_catalogs
    end

    def identifiers
      selectable.map(&:identifier)
    end

    def include?(locale)
      identifiers.include?(normalize(locale))
    end

    def reload!
      @selectable = nil
    end

    def normalize(locale)
      locale.to_s.tr("_", "-").split("-").map.with_index { |part, index| index.zero? ? part.downcase : part.upcase }.join("-")
    end

    def load_catalogs
      Rails.root.glob("config/locales/*.yml").sort.filter_map do |path|
        identifier = path.basename(".yml").to_s
        next unless identifier.match?(%r{\A[a-z]{2,3}(?:-[A-Za-z0-9]+)*\z})

        data = YAML.safe_load_file(path, aliases: false)
        validate_catalog!(path, identifier, data)
        Catalog.new(identifier: normalize(identifier), name: data.fetch(identifier).fetch("locale_name").to_s.strip)
      rescue Psych::Exception, KeyError, TypeError => error
        raise CatalogError, "#{path}: #{error.message}"
      end
    end

    def validate_catalog!(path, identifier, data)
      unless data.is_a?(Hash) && data.keys == [identifier]
        raise CatalogError, "#{path} must have exactly one top-level key: #{identifier}"
      end

      catalog = data.fetch(identifier)
      unless catalog.is_a?(Hash) && catalog["locale_name"].to_s.strip != ""
        raise CatalogError, "#{path} must define a non-empty #{identifier}.locale_name"
      end
    end
    private_class_method :validate_catalog!
  end
end
