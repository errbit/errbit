# frozen_string_literal: true

require "yaml"

module Errbit
  module Locales
    Catalog = Data.define(:identifier, :name)

    class CatalogError < StandardError; end

    module_function

    def selectable
      return load_catalogs if Rails.application.config.enable_reloading

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
      locale.to_s.tr("_", "-").split("-").map.with_index do |part, index|
        if index.zero?
          part.downcase
        elsif part.match?(/\A[A-Za-z]{4}\z/)
          part.capitalize
        elsif part.match?(/\A(?:[A-Za-z]{2}|\d{3})\z/)
          part.upcase
        else
          part
        end
      end.join("-")
    end

    def load_catalogs
      source = YAML.safe_load_file(Rails.root.join("config/locales/en.yml"), aliases: false).fetch("en")

      Rails.root.glob("config/locales/*.yml").sort.filter_map do |path|
        identifier = path.basename(".yml").to_s
        validate_identifier!(path, identifier)

        validate_unique_keys!(path)
        data = YAML.safe_load_file(path, aliases: false)
        validate_catalog!(path, identifier, data)
        validate_translation_shape!(path, identifier, data.fetch(identifier), source)
        Catalog.new(identifier: normalize(identifier), name: data.fetch(identifier).fetch("locale_name").to_s.strip)
      rescue Psych::Exception, KeyError, TypeError => error
        raise CatalogError, "#{path}: #{error.message}"
      end
    end

    def validate_identifier!(path, identifier)
      unless identifier.match?(%r{\A[a-z]{2,3}(?:-[A-Za-z0-9]+)*\z})
        raise CatalogError, "#{path} has an invalid locale filename"
      end
      unless identifier == normalize(identifier)
        raise CatalogError, "#{path} must use the canonical locale identifier #{normalize(identifier)}"
      end
    end
    private_class_method :validate_identifier!

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

    def validate_translation_shape!(path, identifier, catalog, source)
      compare_translation_shapes!(path, identifier, catalog, source, identifier)
    end
    private_class_method :validate_translation_shape!

    def compare_translation_shapes!(path, key_path, translation, source, identifier)
      if translation.is_a?(Hash) != source.is_a?(Hash)
        raise CatalogError, "#{path} #{key_path} must preserve the translation value type"
      end
      return unless translation.is_a?(Hash) && source.is_a?(Hash)

      if pluralization_hash?(source)
        valid_keys = %w[zero one two few many other]
        invalid = translation.keys - valid_keys
        missing = pluralization_keys(identifier) - translation.keys
        unless invalid.empty? && missing.empty?
          keys = (invalid + missing).uniq.join(", ")
          raise CatalogError, "#{path} #{key_path} has invalid or missing pluralization keys: #{keys}"
        end
      end

      source.each do |key, source_value|
        next unless translation.key?(key)

        compare_translation_shapes!(path, "#{key_path}.#{key}", translation[key], source_value, identifier)
        compare_interpolations!(path, "#{key_path}.#{key}", translation[key], source_value)
      end
    end
    private_class_method :compare_translation_shapes!

    def pluralization_keys(identifier)
      rule = I18n.backend.send(:pluralizer, identifier)
      (0..200).map { |count| rule.call(count).to_s }.uniq
    rescue NoMethodError
      %w[one other]
    end
    private_class_method :pluralization_keys

    def pluralization_hash?(value)
      value.keys.all? { |key| %w[zero one two few many other].include?(key) } && value.keys.any?
    end
    private_class_method :pluralization_hash?

    def compare_interpolations!(path, key_path, translation, source)
      return unless translation.is_a?(String) && source.is_a?(String)

      expected = source.scan(/%\{([^}]+)\}/).flatten.uniq.sort
      actual = translation.scan(/%\{([^}]+)\}/).flatten.uniq.sort
      return if actual == expected

      raise CatalogError, "#{path} #{key_path} must preserve interpolation variables"
    end
    private_class_method :compare_interpolations!

    def validate_unique_keys!(path)
      document = Psych.parse_file(path)
      check_unique_mapping_keys!(document, path)
    rescue Psych::Exception => error
      raise CatalogError, "#{path}: #{error.message}"
    end
    private_class_method :validate_unique_keys!

    def check_unique_mapping_keys!(node, path)
      if node.is_a?(Psych::Nodes::Mapping)
        keys = node.children.each_slice(2).map { |key, _value| key.value }
        duplicate = keys.group_by(&:itself).find { |_key, values| values.length > 1 }&.first
        raise CatalogError, "#{path} contains duplicate key: #{duplicate}" if duplicate
      end

      Array(node.children).each { |child| check_unique_mapping_keys!(child, path) } if node.respond_to?(:children)
    end
    private_class_method :check_unique_mapping_keys!
  end
end
