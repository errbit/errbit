class BacktraceLineDecorator < Draper::Decorator
  EMPTY_STRING = ''.freeze

  def in_app?
    object[:file].match Backtrace::IN_APP_PATH
  end

  def number
    object[:number]
  end

  def column
    object[:column]
  end

  def file
    object[:file]
  end

  def method
    object[:method]
  end

  def file_relative
    file.to_s.sub(Backtrace::IN_APP_PATH, EMPTY_STRING)
  end

  def file_name
    File.basename file
  end

  def to_s
    column = object.try(:[], :column)
    "#{file_relative}:#{number}#{column.present? ? ":#{column}" : ''}"
  end

  def link_to_source_file(app, &block)
    text = h.capture_haml(&block)
    link_to_in_app_source_file(app, text) || text
  end

  def path
    File.dirname(object[:file]).gsub(/^\.$/, '') + "/"
  end

  def decorated_path
    path
      .sub(Backtrace::IN_APP_PATH, '')
      .sub(Backtrace::GEMS_PATH, "<strong>\\1</strong>")
  end

  private
  def link_to_in_app_source_file(app, text)
    return unless in_app?
    if file_name =~ /\.js$/
      link_to_hosted_javascript(app, text)
    else
      link_to_repo_source_file(app, text) ||
      link_to_issue_tracker_file(app, text)
    end
  end

  def link_to_repo_source_file(app, text)
    link_to_github(app, text) || link_to_bitbucket(app, text)
  end

  def link_to_hosted_javascript(app, text)
    if app.asset_host?
      h.link_to(text, "#{app.asset_host}/#{file_relative}", :target => '_blank')
    end
  end

  def link_to_github(app, text = nil)
    return unless app.github_repo?
    href = "%s#L%s" % [app.github_url_to_file(decorated_path + file_name), number]
    h.link_to(text || file_name, href, :target => '_blank')
  end

  def link_to_bitbucket(app, text = nil)
    return unless app.bitbucket_repo?
    href = "%s#%s-%s" % [app.bitbucket_url_to_file(decorated_path + file_name), file_name , number]
    h.link_to(text || file_name, href, :target => '_blank')
  end

  def link_to_issue_tracker_file(app, text = nil)
    return unless app.issue_tracker && app.issue_tracker.respond_to?(:url_to_file)
    href = app.issue_tracker.url_to_file(file_relative, number)
    h.link_to(text || file_name, href, :target => '_blank')
  end
end
