require 'database_cleaner/mongoid/base'
require 'database_cleaner/generic/truncation'
require 'database_cleaner/mongo/truncation'

module DatabaseCleaner
  module Mongoid
    class Truncation
      include ::DatabaseCleaner::Mongoid::Base
      include ::DatabaseCleaner::Generic::Truncation
      include ::DatabaseCleaner::Mongo::Truncation

      private

      def database
        ::Mongoid.database
      end

  end
  end
end
