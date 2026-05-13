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

    def self.document
      first || create!
    end

    def notice_fingerprinter_attributes
      attrs = NOTICE_FINGERPRINTER_FIELDS.each_with_object({}) { |f, h| h[f] = self[f] }
      attrs[:source] = CONFIG_SOURCE_SITE
      attrs
    end
  end
end
