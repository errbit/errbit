# frozen_string_literal: true

if Errbit::Config.sanitize_notice_data == false
  Rails.logger.warn(
    "ERRBIT_SANITIZE_NOTICE_DATA=false. Sensitive notice data may be persisted by Errbit. " \
    "Configure client-side Airbrake filtering where possible."
  )
end
