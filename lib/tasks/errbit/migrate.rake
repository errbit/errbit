# frozen_string_literal: true

namespace :errbit do
  desc "Migrate from MongoDB to SQL"
  task migrate: :environment do
    User.find_each do |user|
      errbit_user = Errbit::User.find_or_initialize_by(bson_id: user.id.to_s)
      errbit_user.attributes = user.attributes_for_migration.compact_blank
      errbit_user.save(validate: false) # TODO: save without validation
    end
  end
end
