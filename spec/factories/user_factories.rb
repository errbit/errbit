Factory.sequence(:user_email) {|n| "user.#{n}@example.com"}

Factory.define :user do |u|
  u.name                  'Clyde Frog'
  u.email                 { Factory.next :user_email }
  u.password              'password'
  u.password_confirmation 'password'
end