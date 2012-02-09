require File.dirname(__FILE__) + '/helper'

class Mongoid::Migration
  class <<self
    attr_accessor :message_count
    def puts(text="")
      self.message_count ||= 0
      self.message_count += 1
    end
  end
end

module Mongoid
  class TestCase < ActiveSupport::TestCase #:nodoc:

    def setup
      Mongoid::Migration.verbose = true
      # same as db:drop command in lib/mongoid_rails_migrations/mongoid_ext/railties/database.rake
      Mongoid.master.collections.each {|col| col.drop_indexes && col.drop unless ['system.indexes', 'system.users'].include?(col.name) }
    end

    def teardown; end

    def test_drop_works
      assert_equal 0, Mongoid::Migrator.current_version, "db:drop should take us down to version 0"
    end

    def test_finds_migrations
      assert Mongoid::Migrator.new(:up, MIGRATIONS_ROOT + "/valid").migrations.size == 2
      assert_equal 2, Mongoid::Migrator.new(:up, MIGRATIONS_ROOT + "/valid").pending_migrations.size
    end

    def test_migrator_current_version
      Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/valid", 20100513054656)
      assert_equal(20100513054656, Mongoid::Migrator.current_version)
    end

    def test_migrator
      assert SurveySchema.first.nil?, "All SurveySchemas should be clear before migration run"

      Mongoid::Migrator.up(MIGRATIONS_ROOT + "/valid")

      assert_equal 20100513063902, Mongoid::Migrator.current_version
      assert !SurveySchema.first.nil?

      Mongoid::Migrator.down(MIGRATIONS_ROOT + "/valid")
      assert_equal 0, Mongoid::Migrator.current_version

      assert SurveySchema.create(:label => 'Questionable Survey')
      assert_equal 1, SurveySchema.all.size
    end

    def test_migrator_two_up_and_one_down
      assert SurveySchema.where(:label => 'Baseline Survey').first.nil?
      assert_equal 0, SurveySchema.all.size

      Mongoid::Migrator.up(MIGRATIONS_ROOT + "/valid", 20100513054656)

      assert !SurveySchema.where(:label => 'Baseline Survey').first.nil?
      assert_equal 1, SurveySchema.all.size

      assert SurveySchema.where(:label => 'Improvement Plan Survey').first.nil?

      Mongoid::Migrator.up(MIGRATIONS_ROOT + "/valid", 20100513063902)
      assert_equal 20100513063902, Mongoid::Migrator.current_version

      assert !SurveySchema.where(:label => 'Improvement Plan Survey').first.nil?
      assert_equal 2, SurveySchema.all.size

      Mongoid::Migrator.down(MIGRATIONS_ROOT + "/valid", 20100513054656)
      assert_equal 20100513054656, Mongoid::Migrator.current_version

      assert SurveySchema.where(:label => 'Improvement Plan Survey').first.nil?
      assert !SurveySchema.where(:label => 'Baseline Survey').first.nil?
      assert_equal 1, SurveySchema.all.size
    end

    def test_finds_pending_migrations
      Mongoid::Migrator.up(MIGRATIONS_ROOT + "/valid", 20100513054656)
      pending_migrations = Mongoid::Migrator.new(:up, MIGRATIONS_ROOT + "/valid").pending_migrations

      assert_equal 1, pending_migrations.size
      assert_equal pending_migrations[0].version, 20100513063902
      assert_equal pending_migrations[0].name, 'AddImprovementPlanSurveySchema'
    end

    def test_migrator_rollback
      Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/valid")
      assert_equal(20100513063902, Mongoid::Migrator.current_version)

      Mongoid::Migrator.rollback(MIGRATIONS_ROOT + "/valid")
      assert_equal(20100513054656, Mongoid::Migrator.current_version)

      Mongoid::Migrator.rollback(MIGRATIONS_ROOT + "/valid")
      assert_equal(0, Mongoid::Migrator.current_version)
    end

    def test_migrator_forward
      Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/valid", 20100513054656)
      assert_equal(20100513054656, Mongoid::Migrator.current_version)

      Mongoid::Migrator.forward(MIGRATIONS_ROOT + "/valid", 20100513063902)
      assert_equal(20100513063902, Mongoid::Migrator.current_version)
    end

    def test_migrator_with_duplicate_names
      assert_raise(Mongoid::DuplicateMigrationNameError) do
        Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/duplicate/names", nil)
      end
    end

    def test_migrator_with_duplicate_versions
      assert_raise(Mongoid::DuplicateMigrationVersionError) do
        Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/duplicate/versions", nil)
      end
    end

    def test_migrator_with_missing_version_numbers
      assert_raise(Mongoid::UnknownMigrationVersionError) do
        Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/valid", 500)
      end
    end

    def test_default_state_of_timestamped_migrations
      assert Mongoid.config.timestamped_migrations, "Mongoid.config.timestamped_migrations should default to true"
    end

    def test_timestamped_migrations_generates_non_sequential_next_number
      next_number = Mongoid::Generators::Base.next_migration_number(MIGRATIONS_ROOT + "/valid")
      assert_not_equal "20100513063903", next_number
    end

    def test_turning_off_timestamped_migrations
      Mongoid.config.timestamped_migrations = false
      next_number = Mongoid::Generators::Base.next_migration_number(MIGRATIONS_ROOT + "/valid")
      assert_equal "20100513063903", next_number
    end

  end
end