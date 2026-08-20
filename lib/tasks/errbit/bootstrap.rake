# frozen_string_literal: true

namespace :errbit do
  desc "Refuse to boot a MongoDB installation until its SQL migration is verified"
  task ensure_sql_cutover: :environment do
    legacy_data = [::User, ::SiteConfig, ::App, ::Backtrace, ::Problem, ::Err, ::Notice, ::Comment].any?(&:exists?)
    next unless legacy_data
    next if File.exist?(Errbit::MigrateHelpers.cutover_marker)

    raise <<~MESSAGE
      MongoDB data was detected but its SQL migration has not been verified.
      Back up MongoDB, run `bin/rails errbit:migrate:all`, and start Errbit again.
    MESSAGE
  end

  desc "Migrate, configure, verify the cutover state, and seed the SQL database"
  task bootstrap: ["db:migrate", "errbit:sqlite:configure", "errbit:ensure_sql_cutover", "db:seed"]

  desc "Create legacy MongoDB indexes before running Mongo-to-SQL migration"
  task prepare_mongo_migration: "db:mongoid:create_indexes"
end
