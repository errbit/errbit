module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      module Validations #:nodoc:
        # Validate that the parameters of the reciever conform to RFC 2445
        # If errors are found they will be added to the receivers errors
        #
        # Whenever any of the parameters are set, e.g. with:
        #    recurrence_rule.count = 2
        # the errors will be reset
        def valid?
          validate if @errors.nil?
          errors.empty?
        end

        # Return any errors found during validation
        # See #valid?
        def errors
          @errors ||= []
        end

        def reset_errors # :nodoc:
          @errors = nil
        end

        # Used by #valid? to validate that the parameters of the reciever conform to RFC 2445
        # If errors are found they will be added to the receivers errors
        #
        # Whenever any of the parameters are set, e.g. with:
        #    recurrence_rule.count = 2
        # the errors will be reset
        def validate
          @errors = []
          validate_termination
          validate_freq
          validate_interval
          validate_int_by_list(:bysecond, (0..59))
          validate_int_by_list(:byminute, (0..59))
          validate_int_by_list(:byhour, (0..23))
          validate_int_by_list(:bymonth, (1..12))
          validate_bysetpos
          validate_byday_list
          validate_bymonthday_list
          validate_byyearday_list
          validate_byweekno_list
          validate_wkst
        end

        def validate_termination
          errors << "COUNT and UNTIL cannot both be specified" if @count && @until
        end

        def validate_freq
          if @freq
            unless %w{
              SECONDLY MINUTELY HOURLY DAILY
              WEEKLY MONTHLY YEARLY
              }.include?(@freq.upcase)
              errors <<  "Invalid frequency '#{@freq}'"
            end
          else
            errors << "RecurrenceRule must have a value for FREQ"
          end
        end

        def validate_interval
          if @interval
            errors << "interval must be a positive integer" unless @interval > 0
          end
        end

        def validate_wkst
          errors << "#{wkst.inspect} is invalid for wkst" unless %w{MO TU WE TH FR SA SU}.include?(wkst)
        end

        def validate_int_by_list(which, test)
          vals = by_list[which] || []
          vals.each do |val|
            errors << "#{val} is invalid for #{which}" unless test === val
          end
        end

        def validate_bysetpos
          vals = by_list[:bysetpos] || []
          vals.each do |val|
            errors << "#{val} is invalid for bysetpos" unless (-366..-1) === val  || (1..366) === val
          end
          unless vals.empty?
            errors << "bysetpos cannot be used without another by_xxx rule part" unless by_list.length > 1
          end
        end

        def validate_byday_list
          days = by_list[:byday] || []
          days.each do |day|
            errors << "#{day.source.inspect} is not a valid day" unless day.valid?
          end
        end

        def validate_bymonthday_list
          days = by_list[:bymonthday] || []
          days.each do |day|
            errors << "#{day.source.inspect} is not a valid month day" unless day.valid?
          end
        end

        def validate_byyearday_list
          days = by_list[:byyearday] || []
          days.each do |day|
            errors << "#{day.source.inspect} is not a valid year day" unless day.valid?
          end
        end

        def validate_byweekno_list
          days = by_list[:byweekno] || []
          days.each do |day|
            errors << "#{day.source.inspect} is not a valid week number" unless day.valid?
          end
        end
      end
    end
  end
end