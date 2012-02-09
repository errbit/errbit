require 'rails/generators/mongoid/mongoid_generator'

module Mongoid
  module Generators
    class MigrationGenerator < Base

      def create_migration_file
        migration_template "migration.rb", "db/migrate/#{file_name}.rb"
      end

      protected
        attr_reader :migration_action

    end
  end
end