# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:

      # Defines the behaviour for date fields.
      class Date
        include Serializable
        include Timekeeping

        # Deserialize this field from the type stored in MongoDB to the type
        # defined on the model.
        #
        # @example Deserialize the field.
        #   field.deserialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ Date ] The converted date.
        #
        # @since 2.1.0
        def deserialize(object)
         return nil if object.blank?
          if Mongoid::Config.use_utc?
            object.to_date
          else
            ::Date.new(object.year, object.month, object.day)
          end
        end

        protected

        # Converts the date to a time to persist.
        #
        # @example Convert the date to a time.
        #   Date.convert_to_time(date)
        #
        # @param [ Date ] value The date to convert.
        #
        # @return [ Time ] The date converted.
        #
        # @since 2.1.0
        def convert_to_time(value)
          value = ::Date.parse(value) if value.is_a?(::String)
          value = ::Date.civil(*value) if value.is_a?(::Array)
          ::Time.utc(value.year, value.month, value.day)
        end
      end
    end
  end
end
