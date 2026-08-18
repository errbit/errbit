# frozen_string_literal: true

module Errbit
  class SiteConfig < ApplicationRecord
    CONFIG_SOURCE_SITE = "site"
    CONFIG_SOURCE_APP = "app"

    NOTICE_FINGERPRINTER_FIELDS = %i[
      error_class
      message
      backtrace_lines
      component
      action
      environment_name
    ].freeze

    def self.model_name
      @_model_name ||= ActiveModel::Name.new(self, nil, "SiteConfig")
    end

    after_save :denormalize

    def self.document
      first || create!
    end

    def notice_fingerprinter_attributes
      NOTICE_FINGERPRINTER_FIELDS.each_with_object({}) { |field, attrs| attrs[field] = self[field] }.merge(source: CONFIG_SOURCE_SITE)
    end

    def notice_fingerprinter
      self
    end

    def notice_fingerprinter_attributes=(attrs)
      attrs.each do |key, value|
        send(:"#{key}=", value) if NOTICE_FINGERPRINTER_FIELDS.include?(key.to_sym)
      end
    end

    def denormalize
      return if Errbit.migrating?

      attrs = notice_fingerprinter_attributes

      Errbit::App.find_each do |app|
        fingerprinter = app.notice_fingerprinter
        next if fingerprinter&.source && fingerprinter.source != CONFIG_SOURCE_SITE

        if fingerprinter
          fingerprinter.update(attrs)
        else
          app.create_notice_fingerprinter(attrs)
        end
      end
    end
  end
end
