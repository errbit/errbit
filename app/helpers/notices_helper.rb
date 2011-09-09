# encoding: utf-8
module NoticesHelper
  def notice_atom_summary notice
    render :partial => "notices/atom_entry.html.haml", :locals => {:notice => notice}
  end

  def render_line_number(app, line)
    unless Notice.in_app_backtrace_line?(line)
      line['number']
    else
      case true
      when app.github_url? then link_to_github(app, line, line['number'])
      when app.redmine_url? then link_to_redmine(app, line, line['number'])
      else
        line['number']
      end
    end
  end
end
