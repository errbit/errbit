module DatabaseCleaner
  module Mongo
    module Truncation

      def clean
        if @only
          collections.each { |c| c.remove if @only.include?(c.name) }
        else
          collections.each { |c| c.remove unless @tables_to_exclude.include?(c.name) }
        end
        true
      end

      private

      def collections
        database.collections.select { |c| c.name !~ /^system\./ }
      end

    end
  end
end
