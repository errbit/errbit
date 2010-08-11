Factory.sequence(:app_name) {|n| "App ##{n}"}
Factory.sequence(:email) {|n| "email#{n}@example.com"}

Factory.define(:app) do |p|
  p.name { Factory.next :app_name }
end

Factory.define(:app_with_watcher, :parent => :app) do |p|
  p.after_create {|app|
    Factory(:watcher, :app => app)
  }
end

Factory.define(:watcher) do |w|
  w.app {|p| p.association :app}
  w.email   { Factory.next :email }
end

Factory.define(:deploy) do |d|
  d.app       {|p| p.association :app}
  d.username      'clyde.frog'
  d.repository    'git@github.com/jdpace/errbit.git'
  d.environment   'production'
  d.revision      '2e601cb575ca97f1a1097f12d0edfae241a70263'
end