Fabricate.sequence(:name) {|n| "John #{n} Doe"}
Fabricate.sequence(:word) {|n| "word#{n}"}
Fabricate.sequence(:app_name) {|n| "App ##{n}"}
Fabricate.sequence(:email) {|n| "email#{n}@example.com"}
Fabricate.sequence(:user_email) {|n| "user.#{n}@example.com"}

