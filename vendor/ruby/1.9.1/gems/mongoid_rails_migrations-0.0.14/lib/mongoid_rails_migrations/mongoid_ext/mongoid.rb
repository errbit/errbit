# encoding: utf-8
module Mongoid
  # Specify whether or not to use timestamps for migration versions
  # NOTE: newer style is a module
  # Config.module_eval would work for both but still need to determine the type
  # that's why we do it the ug way.
  if Config.is_a? Class
    # older mongoid style; pre 2.0.0.rc.1
    Config.module_eval do
      cattr_accessor :timestamped_migrations
      class_variable_set(:@@timestamped_migrations, true) unless class_variable_get(:@@timestamped_migrations)

      def self.reset
        @@timestamped_migrations = true
      end
    end
  else # module
    Config.module_eval do
      # newer mongoid style; >= 2.0.0.rc.1
      option :timestamped_migrations, :default => true
    end
  end
end