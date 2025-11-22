# frozen_string_literal: true

Fabricator :user do
  name "Clyde Frog"

  email { sequence(:user_email) { |n| "user.#{n}@example.com" } }
end

Fabricator :admin, from: :user do
  admin true
end
