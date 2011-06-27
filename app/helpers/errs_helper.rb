module ErrsHelper
  
  def last_notice_at err
    err.last_notice_at || err.created_at
  end

  def err_confirm
    Errbit::Config.confirm_resolve_err === false ? nil : 'Seriously?'
  end
  
  def link_to_github app, notice
    file_name   = notice.top_in_app_backtrace_line['file'].split('/').last
    file_path   = notice.top_in_app_backtrace_line['file'].gsub('[PROJECT_ROOT]', '')
    line_number = notice.top_in_app_backtrace_line['number']
    link_to(file_name, "#{app.github_url_to_file(file_path)}#L#{line_number}", :target => '_blank')
  end
  
end