# frozen_string_literal: true

namespace :errbit do
  desc "Migrate and seed the SQL database"
  task bootstrap: ["db:migrate", "db:seed"]

  desc "Create legacy MongoDB indexes before running Mongo-to-SQL migration"
  task prepare_mongo_migration: "db:mongoid:create_indexes"
end
