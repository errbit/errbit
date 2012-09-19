# encoding: utf-8
module NoticesHelper
  def in_app_backtrace_line?(line)
    !!(line['file'] =~ %r{^\[PROJECT_ROOT\]/(?!(vendor))})
  end

  def notice_atom_summary(notice)
    render "notices/atom_entry.html.haml", :notice => notice
  end

  def link_to_source_file(app, line, &block)
    text = capture_haml(&block)
    if in_app_backtrace_line?(line)
      return link_to_github(app, line, text) if app.github_repo?
      return link_to_bitbucket(app, line, text) if app.bitbucket_repo?
      if app.issue_tracker && app.issue_tracker.respond_to?(:url_to_file)
        # Return link to file on tracker if issue tracker supports this
        return link_to_issue_tracker_file(app, line, text)
      end
    end
    text
  end

  def filepath_parts(file)
    [file.split('/').last, file.gsub('[PROJECT_ROOT]', '')]
  end

  def link_to_github(app, line, text = nil)
    file_name, file_path = filepath_parts(line['file'])
    href = "%s#L%s" % [app.github_url_to_file(file_path), line['number']]
    link_to(text || file_name, href, :target => '_blank')
  end

  def link_to_bitbucket(app, line, text = nil)
    file_name, file_path = filepath_parts(line['file'])
    href = "%s#cl-%s" % [app.bitbucket_url_to_file(file_path), line['number']]
    link_to(text || file_name, href, :target => '_blank')
  end

  def link_to_issue_tracker_file(app, line, text = nil)
    file_name, file_path = filepath_parts(line['file'])
    href = app.issue_tracker.url_to_file(file_path, line['number'])
    link_to(text || file_name, href, :target => '_blank')
  end

  # Group lines into sections of in-app files and external files
  # (An implementation of Enumerable#chunk so we don't break 1.8.7 support.)
  def grouped_lines(lines)
    line_groups = []
    lines.each do |line|
      in_app = in_app_backtrace_line?(line)
      if line_groups.last && line_groups.last[0] == in_app
        line_groups.last[1] << line
      else
        line_groups << [in_app, [line]]
      end
    end
    line_groups
  end

  def path_for_backtrace_line(line)
    path = File.dirname(line['file'])
    return '' if path == '.'
    # Remove [PROJECT_ROOT]
    path.gsub!('[PROJECT_ROOT]/', '')
    # Make gem name bold if starts with [GEM_ROOT]/gems
    path.gsub!(/\[GEM_ROOT\]\/gems\/([^\/]+)/, "<strong>\\1</strong>")
    (path << '/').html_safe
  end

  def file_for_backtrace_line(line)
    file = File.basename(line['file'])
  end
end

