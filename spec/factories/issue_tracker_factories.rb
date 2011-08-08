Factory.define :generic_tracker, :class => IssueTracker do |e|
  e.api_token { Factory.next :word }
  e.project_id { Factory.next :word }
  e.association :app, :factory => :app
end

Factory.define :lighthouseapp_tracker, :parent => :generic_tracker do |e|
  e.issue_tracker_type 'lighthouseapp'
  e.account { Factory.next :word }
end

Factory.define :redmine_tracker, :parent => :generic_tracker do |e|
  e.issue_tracker_type 'redmine'
  e.account { "http://#{Factory.next(:word)}.com" }
end

Factory.define :pivotal_tracker, :parent => :generic_tracker do |e|
  e.issue_tracker_type 'pivotal'
end

Factory.define :mingle_tracker, :parent => :generic_tracker do |t|
  t.issue_tracker_type 'mingle'
  t.account  "https://mingle.example.com"
  t.ticket_properties 'card_type = Defect, defect_status = open, priority = essential'
  t.username "test_user"
  t.password "test_password"
end

