# frozen_string_literal: true

namespace :errbit do
  desc "Add a demo app & errors to your database (for development)"
  task dev: :environment do
    user = FactoryBot.create(:errbit_user,
      name: "John Snow",
      email: "me@example.com",
      password: "password",
      admin: true
    )

    app = FactoryBot.create(:errbit_app,
      name: "Demo App #{Time.zone.now.strftime("%N")}"
    )

    watcher = FactoryBot.create(:errbit_watcher,
      app: app,
      user: user
    )
  end
end
