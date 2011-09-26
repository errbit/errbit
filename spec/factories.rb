Factory.sequence(:name) {|n| "John #{n} Doe"}
Factory.sequence(:word) {|n| "word#{n}"}
Factory.sequence(:app_name) {|n| "App ##{n}"}
Factory.sequence(:email) {|n| "email#{n}@example.com"}
Factory.sequence(:user_email) {|n| "user.#{n}@example.com"}

