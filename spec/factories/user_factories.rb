Factory.define :user do |u|
  u.name                  'Clyde Frog'
  u.email                 { Factory.next :user_email }
  u.password              'password'
  u.password_confirmation 'password'
end

Factory.define :admin, :parent => :user do |a|
  a.admin true
end