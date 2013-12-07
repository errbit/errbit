Fabricator(:app) do
  name { sequence(:app_name){|n| "App ##{n}"} }
  repository_branch 'master'
end

Fabricator(:app_with_watcher, :from => :app) do
  after_create do |parent|
    parent.watchers.create Fabricate.attributes_for(:watcher, :app => parent)
  end
end

Fabricator(:app_with_user_watcher, :from => :app) do
  after_create do |parent|
    parent.watchers.create Fabricate.attributes_for(:user_watcher, :app => parent)
  end
end

Fabricator(:app_with_deploys, :from => :app) do
  after_create { |parent|
    3.times do
      Fabricate(:deploy, :app => parent)
    end
  }
end

Fabricator(:watcher) do
  app
  watcher_type 'email'
  email   { sequence(:email){|n| "email#{n}@example.com"} }
end

Fabricator(:user_watcher, :from => :watcher) do
  user
  watcher_type 'user'
end

Fabricator(:deploy) do
  app
  username      'clyde.frog'
  repository    'git@github.com/errbit/errbit.git'
  environment   'production'
  revision      { SecureRandom.hex(10) }
end

