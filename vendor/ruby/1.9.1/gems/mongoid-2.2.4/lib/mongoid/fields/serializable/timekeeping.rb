# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:

      # This module contains shared behaviour for date conversions.
      module Timekeeping

        # When reading the field do we need to cast the value? This holds true when
        # times are stored or for big decimals which are stored as strings.
        #
        # @example Typecast on a read?
        #   field.cast_on_read?
        #
        # @return [ true ] Date fields cast on read.
        #
        # @since 2.1.0
        def cast_on_read?; true; end

        # Deserialize this field from the type stored in MongoDB to the type
        # defined on the model.
        #
        # @example Deserialize the field.
        #   field.deserialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ Time ] The converted time.
        #
        # @since 2.1.0
        def deserialize(object)
          return nil if object.blank?
          object = object.getlocal unless Mongoid::Config.use_utc?
          if Mongoid::Config.use_activesupport_time_zone?
            time_zone = Mongoid::Config.use_utc? ? 'UTC' : ::Time.zone
            object = object.in_time_zone(time_zone)
          end
          object
        end

        # Serialize the object from the type defined in the model to a MongoDB
        # compatible object to store.
        #
        # @example Serialize the field.
        #   field.serialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ Time ] The converted UTC time.
        #
        # @since 2.1.0
        def serialize(object)
          return nil if object.blank?
          time = convert_to_time(object)
          strip_milliseconds(time).utc
        end

        # Convert the provided object to a UTC time to store in the database.
        #
        # @example Set the time.
        #   Time.convert_to_time(Date.today)
        #
        # @param [ String, Date, DateTime, Array ] value The object to cast.
        #
        # @return [ Time ] The object as a UTC time.
        #
        # @since 1.0.0
        def convert_to_time(value)
          time = Mongoid::Config.use_activesupport_time_zone? ? ::Time.zone : ::Time
          case value
            when ::String
              time.parse(value)
            when ::DateTime
              time.local(value.year, value.month, value.day, value.hour, value.min, value.sec)
            when ::Date
              time.local(value.year, value.month, value.day)
            when ::Array
              time.local(*value)
            else
              value
          end
        end

        # Strip the milliseconds off the time.
        #
        # @todo Durran: Why is this here? Still need time refactoring.
        #
        # @example Strip.
        #   Time.strip_millseconds(Time.now)
        #
        # @param [ Time ] time The time to strip.
        #
        # @return [ Time ] The time without millis.
        #
        # @since 2.1.0
        def strip_milliseconds(time)
          ::Time.at(time.to_i)
        end
      end
    end
  end
end
