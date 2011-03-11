puts "Seeding database"
puts "-------------------------------"

# Create an initial Admin User
admin_email = "errbit@#{Errbit::Config.host}"
admin_pass  = 'password'

puts "Creating an initial admin user:"
puts "-- email:    #{admin_email}"
puts "-- password: #{admin_pass}"
puts ""
puts "Be sure to change these credentials ASAP!"
user = User.where(:email => admin_email).first || User.new({
  :name                   => 'Errbit Admin',
  :email                  => admin_email,
  :password               => admin_pass,
  :password_confirmation  => admin_pass
})

user.admin = true
user.save!
