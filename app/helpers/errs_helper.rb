module ErrsHelper
  
  def last_notice_at(problem)
    problem.last_notice_at || problem.created_at
  end
  
  def err_confirm
    Errbit::Config.confirm_resolve_err === false ? nil : 'Seriously?'
  end
  
  def link_to_github(app, line, text=nil)
    file_name   = line['file'].split('/').last
    file_path   = line['file'].gsub('[PROJECT_ROOT]', '')
    line_number = line['number']
    link_to(text || file_name, "#{app.github_url_to_file(file_path)}#L#{line_number}", :target => '_blank')
  end
  
end