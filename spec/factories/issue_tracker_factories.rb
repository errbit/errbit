Factory.define :issue_tracker do |e|
  e.api_token { Factory.next :word }
  e.project_id { Factory.next :word }
  e.association :app, :factory => :app
  e.account { Factory.next :word }
  e.username { Factory.next :word }
  e.password { Factory.next :word }
end

%w(lighthouse pivotal_labs fogbugz).each do |t|
  Factory.define "#{t}_tracker".to_sym, :parent => :issue_tracker, :class => "#{t}_tracker".to_sym do |e|; end
end

Factory.define :redmine_tracker, :parent => :issue_tracker, :class => :redmine_tracker do |e|
  e.account 'http://redmine.example.com'
end

Factory.define :mingle_tracker, :parent => :issue_tracker, :class => :mingle_tracker do |e|
  e.account 'https://mingle.example.com'
  e.ticket_properties 'card_type = Defect, defect_status = open, priority = essential'
end

Factory.define :github_issues_tracker, :parent => :issue_tracker, :class => :github_issues_tracker do |e|
  e.project_id 'test_account/test_project'
  e.username 'test_username'
end

