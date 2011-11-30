Fabricator :issue_tracker do
  app!
  api_token { sequence :word }
  project_id { sequence :word }
  account { sequence :word }
  username { sequence :word }
  password { sequence :word }
end

%w(lighthouse pivotal_labs fogbugz).each do |t|
  Fabricator "#{t}_tracker".to_sym, :from => :issue_tracker, :class_name => "#{t}_tracker".to_sym
end

Fabricator :redmine_tracker, :from => :issue_tracker, :class_name => :redmine_tracker do
  account 'http://redmine.example.com'
end

Fabricator :mingle_tracker, :from => :issue_tracker, :class_name => :mingle_tracker do
  account 'https://mingle.example.com'
  ticket_properties 'card_type = Defect, defect_status = open, priority = essential'
end

Fabricator :github_issues_tracker, :from => :issue_tracker, :class_name => :github_issues_tracker do
  project_id 'test_account/test_project'
  username 'test_username'
end

