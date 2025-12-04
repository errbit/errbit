# frozen_string_literal: true

module Errbit
  class SiteConfig < ApplicationRecord
    CONFIG_SOURCE_SITE = "site"
    CONFIG_SOURCE_APP = "app"

    # Get the one and only SiteConfig document
    def self.document
      first || create
    end
  end
end
