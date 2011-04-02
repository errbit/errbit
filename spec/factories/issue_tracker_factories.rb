Factory.define :lighthouseapp_tracker, :class => IssueTracker do |e|
  e.issue_tracker_type 'lighthouseapp'
  e.account { Factory.next :word }
  e.api_token { Factory.next :word }
  e.project_id { Factory.next :word }
  e.association :app, :factory => :app
end

Factory.define :redmine_tracker, :parent => :lighthouseapp_tracker do |e|
  e.issue_tracker_type 'redmine'
  e.account { "http://#{Factory.next(:word)}.com" }
end