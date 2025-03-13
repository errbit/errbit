require "fileutils"

namespace :errbit do
  desc "Seed and index the DB"
  task bootstrap: %w(db:seed db:mongoid:create_indexes)
end
