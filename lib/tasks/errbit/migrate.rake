# frozen_string_literal: true

namespace :errbit do
  desc "Migrate from MongoDB to SQL"
  task migrate: :environment do
    User.each do |user|
      errbit_user = Errbit.new
      errbit_user.name = user.name
      errbit_user.admin = user.admin
      errbit_user.per_page = user.per_page
      errbit_user.time_zone = user.time_zone
      errbit_user.github_login = user.github_login
      errbit_user.github_oauth_token = user.github_oauth_token
      errbit_user.google_uid = user.google_uid
      errbit_user.save!
    end
  end
end
