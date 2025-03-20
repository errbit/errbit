# frozen_string_literal: true

namespace :errbit do
  desc "Seed and index the DB"
  task bootstrap: ["db:seed", "db:mongoid:create_indexes"]
end
