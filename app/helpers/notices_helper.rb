# encoding: utf-8
module NoticesHelper
  def notice_atom_summary notice
    render :partial => "notices/atom_entry.html.haml", :locals => {:notice => notice}
  end

  def link_to_source_file(app, line, text)
    if Notice.in_app_backtrace_line?(line)
      return link_to_github(app, line, text) if app.github_url?
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

  def link_to_issue_tracker_file(app, line, text = nil)
    file_name, file_path = filepath_parts(line['file'])
    href = app.issue_tracker.url_to_file(file_path, line['number'])
    link_to(text || file_name, href, :target => '_blank')
  end
end

