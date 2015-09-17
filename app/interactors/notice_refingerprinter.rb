class NoticeRefingerprinter
  LOG_EVERY = 100
  LOG_ITR = '%.1f%% complete, %i notice(s) remaining'
  LOG_START = 'Regenerating notice fingerprints for %i notices'

  def self.run
    count = Notice.count
    puts format(LOG_START, count)

    Notice.no_timeout.each_with_index do |notice, index|
      refingerprint(notice)

      next unless (index + 1) % LOG_EVERY == 0
      puts format(LOG_ITR, (index * 100 / count), count - index)
    end

    puts 'Finished generating notice fingerprints'
  end

  def self.apps
    @apps ||= App.all.index_by(&:id)
  end

  def self.refingerprint(notice)
    app = apps[notice.try(:err).try(:problem).try(:app_id)]
    app.find_or_create_err!(
      error_class: notice.error_class,
      environment: notice.environment_name,
      fingerprint: app.notice_fingerprinter.generate(app.api_key, notice, notice.backtrace)
    )
  end

  def self.puts(*args)
    Rails.logger.info(*args)
  end
end
