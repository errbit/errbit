Factory.sequence(:project_name) {|n| "Project ##{n}"}
Factory.sequence(:email) {|n| "email#{n}@example.com"}

Factory.define(:project) do |p|
  p.name { Factory.next :project_name }
end

Factory.define(:project_with_watcher, :parent => :project) do |p|
  p.after_create {|project|
    Factory(:watcher, :project => project)
  }
end

Factory.define(:watcher) do |w|
  w.project {|p| p.association :project}
  w.email   { Factory.next :email }
end

Factory.define(:deploy) do |d|
  d.project       {|p| p.association :project}
  d.username      'clyde.frog'
  d.repository    'git@github.com/jdpace/hypnotoad.git'
  d.environment   'production'
  d.revision      '2e601cb575ca97f1a1097f12d0edfae241a70263'
end