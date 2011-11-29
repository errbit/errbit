Fabricator :user do
  name                  'Clyde Frog'
  email                 { sequence(:user_email) {|n| "user.#{n}@example.com"} }
  password              'password'
  password_confirmation 'password'
end

Fabricator :admin, :from => :user do
  admin true
end
