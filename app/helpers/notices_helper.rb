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

  # Group lines into sections of in-app files and external files
  # (An implementation of Enumerable#chunk so we don't break 1.8.7 support.)
  def grouped_lines(lines)
    line_groups = []
    lines.each do |line|
      in_app = Notice.in_app_backtrace_line?(line)
      if line_groups.last && line_groups.last[0] == in_app
        line_groups.last[1] << line
      else
        line_groups << [in_app, [line]]
      end
    end
    line_groups
  end

  def rows_for_line_segment(lines, start, length, row_class = nil)
    html = ""
    lines[start, length].each do |line|
      html << render(:partial => "notices/backtrace_line", :locals => {:line => line, :row_class => row_class})
    end
    html.html_safe
  end

  def path_for_backtrace_line(line)
    path = File.dirname(line['file'])
    path == "." ? "" : path + '/'
  end

  def file_for_backtrace_line(line)
    file = File.basename(line['file'])
    line['number'].present? ? "#{file}:#{line['number']}" : file
  end
end

