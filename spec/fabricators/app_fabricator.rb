Fabricator(:app) do
  name { sequence(:app_name) { |n| "App ##{n}" } }
  repository_branch 'master'
end

Fabricator(:app_with_watcher, from: :app) do
  watchers(count: 1) do |parent, _i|
    Fabricate.build(:watcher, app: parent)
  end
end

Fabricator(:watcher) do
  app
  watcher_type 'email'
  email { sequence(:email) { |n| "email#{n}@example.com" } }
end

Fabricator(:user_watcher, from: :watcher) do
  user
  watcher_type 'user'
end
