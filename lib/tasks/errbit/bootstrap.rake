# frozen_string_literal: true

namespace :errbit do
  desc "Migrate the SQL schema and seed the DB"
  task bootstrap: ["db:migrate", "db:seed"]
end
