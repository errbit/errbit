Factory.define(:app) do |p|
  p.name { Factory.next :app_name }
end

Factory.define(:app_with_watcher, :parent => :app) do |p|
  p.after_create {|app|
    Factory(:watcher, :app => app)
  }
end

Factory.define(:watcher) do |w|
  w.association :app
  w.watcher_type 'email'
  w.email   { Factory.next :email }
end

Factory.define(:user_watcher, :parent => :watcher) do |w|
  w.watcher_type 'user'
  w.association :user
end

Factory.define(:deploy) do |d|
  d.app           {|p| p.association :app}
  d.username      'clyde.frog'
  d.repository    'git@github.com/errbit/errbit.git'
  d.environment   'production'
  d.revision      ActiveSupport::SecureRandom.hex(10)
end

