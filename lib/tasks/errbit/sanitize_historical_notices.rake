# frozen_string_literal: true

namespace :errbit do
  desc "Sanitize existing notices (dry-run by default)"
  task sanitize_historical_notices: :environment do
    dry_run = ENV.fetch("DRY_RUN", "true") != "false"
    sanitizer = HistoricalNoticeSanitizer.new(
      batch_size: ENV.fetch("BATCH_SIZE", HistoricalNoticeSanitizer::DEFAULT_BATCH_SIZE),
      limit: ENV["LIMIT"].presence,
      dry_run: dry_run
    )

    result = sanitizer.run
    mode = dry_run ? "Dry run" : "Applied"
    puts "#{mode}: scanned=#{result.scanned} changed=#{result.changed} unchanged=#{result.unchanged} failed=#{result.failed}"
    abort "Historical notice sanitization failed for #{result.failed} notice(s)." if result.failed.positive?
  end
end
