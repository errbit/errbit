module BacktraceLineHelper
  def link_to_source_file(line, &block)
    text = capture_haml(&block)
     link_to_in_app_source_file(line, text) || link_to_external_source_file(text)
  end

  private
  def link_to_in_app_source_file(line, text)
    return unless line.in_app?
    if line.file_name =~ /\.js$/
      link_to_hosted_javascript(line, text)
    else
      link_to_repo_source_file(line, text) ||
      link_to_issue_tracker_file(line, text)
    end
  end

  def link_to_repo_source_file(line, text)
    link_to_github(line, text) || link_to_bitbucket(line, text)
  end

  def link_to_hosted_javascript(line, text)
    if line.app.asset_host?
      link_to(text, "#{line.app.asset_host}/#{line.file_relative}", :target => '_blank')
    end
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
    href = line.app.issue_tracker.url_to_file(line.file_relative, line.number)
    link_to(text || line.file_name, href, :target => '_blank')
  end

end
