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

    # Routes (`resources :site_config`), form helpers (`form_for @config`),
    # partial paths, and i18n scopes use the un-namespaced "site_config" key.
    # Override model_name so they keep matching even though this class is under
    # `Errbit::`.
    def self.model_name
      @_model_name ||= ActiveModel::Name.new(self, nil, "SiteConfig")
    end

    after_save :denormalize

    def self.document
      first || create!
    end

    def notice_fingerprinter_attributes
      attrs = NOTICE_FINGERPRINTER_FIELDS.each_with_object({}) { |f, h| h[f] = self[f] }
      attrs[:source] = CONFIG_SOURCE_SITE
      attrs
    end

    # Form-side shim: in the Mongoid model the fingerprinter is an embedded
    # document. Here the fields live on SiteConfig itself, so `f.fields_for
    # :notice_fingerprinter` reads/writes the SiteConfig directly. Defining a
    # matching `notice_fingerprinter_attributes=` setter makes Rails' form
    # builder generate the `notice_fingerprinter_attributes` nested key the
    # controller's strong-params expect.
    def notice_fingerprinter
      self
    end

    def notice_fingerprinter_attributes=(attrs)
      attrs.each do |key, value|
        send(:"#{key}=", value) if NOTICE_FINGERPRINTER_FIELDS.include?(key.to_sym)
      end
    end

    # Propagate fingerprinter changes to every Errbit::App that is still
    # following site-wide settings. Mirrors the Mongoid SiteConfig#denormalize
    # callback. Apps that have opted into their own per-app fingerprinter
    # (source = CONFIG_SOURCE_APP) are left alone.
    def denormalize
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
