module BacktraceLineHelper
  def link_to_source_file(line, app, &block)
    text = capture_haml(&block)
    link_to_in_app_source_file(line, app, text) || text
  end

  private
  def link_to_in_app_source_file(line, app, text)
    return unless line.in_app?
    if line.file_name =~ /\.js$/
      link_to_hosted_javascript(line, app, text)
    else
      link_to_repo_source_file(line, app, text) ||
      link_to_issue_tracker_file(line, app, text)
    end
  end

  def link_to_repo_source_file(line, app, text)
    link_to_github(line, app, text) || link_to_bitbucket(line, app, text)
  end

  def link_to_hosted_javascript(line, app, text)
    if app.asset_host?
      link_to(text, "#{app.asset_host}/#{line.file_relative}", :target => '_blank')
    end
  end

  def link_to_github(line, app, text = nil)
    return unless app.github_repo?
    href = "%s#L%s" % [app.github_url_to_file(line.decorated_path + line.file_name), line.number]
    link_to(text || line.file_name, href, :target => '_blank')
  end

  def link_to_bitbucket(line, app, text = nil)
    return unless app.bitbucket_repo?
    href = "%s#cl-%s" % [app.bitbucket_url_to_file(line.decorated_path + line.file_name), line.number]
    link_to(text || line.file_name, href, :target => '_blank')
  end

  def link_to_issue_tracker_file(line, app, text = nil)
    return unless app.issue_tracker && app.issue_tracker.respond_to?(:url_to_file)
    href = app.issue_tracker.url_to_file(line.file_relative, line.number)
    link_to(text || line.file_name, href, :target => '_blank')
  end

end
