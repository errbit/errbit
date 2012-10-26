module BacktraceLineHelper
  def link_to_source_file(line, &block)
    text = capture_haml(&block)
    line.in_app? ? link_to_in_app_source_file(line, text) : link_to_external_source_file(text)
  end

  private
  def link_to_in_app_source_file(line, text)
    link_to_repo_source_file(line, text) || link_to_issue_tracker_file(line, text)
  end

  def link_to_repo_source_file(line, text)
    link_to_github(line, text) || link_to_bitbucket(line, text)
  end

  def link_to_external_source_file(text)
    text
  end

  def link_to_github(line, text = nil)
    return unless line.app.github_repo?
    href = "%s#L%s" % [line.app.github_url_to_file(line.decorated_path + line.file_name), line.number]
    link_to(text || line.file_name, href, :target => '_blank')
  end

  def link_to_bitbucket(line, text = nil)
    return unless line.app.bitbucket_repo?
    href = "%s#cl-%s" % [line.app.bitbucket_url_to_file(line.decorated_path + line.file_name), line.number]
    link_to(text || line.file_name, href, :target => '_blank')
  end

  def link_to_issue_tracker_file(line, text = nil)
    return unless line.app.issue_tracker && line.app.issue_tracker.respond_to?(:url_to_file)
    href = line.app.issue_tracker.url_to_file(line.file, line.number)
    link_to(text || line.file_name, href, :target => '_blank')
  end

end
