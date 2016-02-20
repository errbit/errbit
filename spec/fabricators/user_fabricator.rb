Fabricator :user do
  name 'Clyde Frog'
  email { sequence(:user_email) { |n| "user.#{n}@example.com" } }
  if Errbit::Config.user_has_username
    username { sequence(:username) { |n| "User Name #{n}" } }
  end
  password 'password'
  password_confirmation 'password'
end

Fabricator :admin, from: :user do
  admin true
end
