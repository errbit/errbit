# frozen_string_literal: true

OmniAuth.config.logger = Rails.logger

if Errbit::Config.host.present?
  OmniAuth.config.full_host = Errbit::Config.host
end
