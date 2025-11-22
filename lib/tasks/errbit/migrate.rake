# frozen_string_literal: true

namespace :errbit do
  desc "Migrate from MongoDB to SQL"
  task migrate: :environment do
    User.find_each do |user|
      errbit_user = Errbit::User.find_or_initialize_by(bson_id: user.id.to_s)
      errbit_user.attributes = user.attributes_for_migration.compact_blank
      errbit_user.save(validate: false)
    end

    App.find_each do |app|
      errbit_app = Errbit::App.find_or_initialize_by(bson_id: app.id.to_s)
      # TODO: finish
      errbit_app.save(validate: false)

      app.watchers.find_each do |watcher|
        errbit_watcher = Errbit::Watcher.find_or_initialize_by(bson_id: watcher.id.to_s)
        errbit_watcher.attributes = watcher.attributes_for_migration.compact_blank
        errbit_watcher.save(validate: false)
      end
    end
  end
end
