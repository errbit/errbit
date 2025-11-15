# frozen_string_literal: true

namespace :errbit do
  desc "Migrate from MongoDB to SQL"
  task migrate: :environment do
    User.each do |user|
      errbit_user = Errbit.new
      errbit_user.attributes = user.attributes_for_migration
      errbit_user.save!
    end
  end
end
