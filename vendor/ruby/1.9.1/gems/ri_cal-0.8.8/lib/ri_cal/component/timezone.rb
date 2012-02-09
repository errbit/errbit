module RiCal
  class Component
    #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
    #
    # An Timezone (VTIMEZONE) calendar component describes a timezone used within the calendar.
    # A Timezone has two or more TimezonePeriod subcomponents which describe the transitions between
    # standard and daylight saving time.
    #
    # to see the property accessing methods for this class see the RiCal::Properties::Timezone module
    class Timezone < Component
      
      autoload :TimezonePeriod, "ri_cal/component/timezone/timezone_period.rb"
      autoload :StandardPeriod, "ri_cal/component/timezone/standard_period.rb"
      autoload :DaylightPeriod, "ri_cal/component/timezone/daylight_period.rb"
      
      include RiCal::Properties::Timezone

        # The identifier of the timezone, e.g. "Europe/Paris".
        def identifier
          tzid
        end

        # An alias for identifier.
        def name
          # Don't use alias, as identifier gets overridden.
          identifier
        end
        
        def rational_utc_offset(local) #:nodoc:
          # 86400 is the number of seconds in a day
          RiCal.RationalOffset[period_for_local(local, true).utc_total_offset]
        end

        # Returns the TimezonePeriod for the given UTC time. utc can either be a DateTime,
        # Time or integer timestamp (Time.to_i). Any timezone information in utc is ignored (it is treated as a UTC time).
        def period_for_utc(time)
          last_period(last_before_utc(standard, time), last_before_utc(daylight, time))
        end

        # Returns the set of TimezonePeriod instances that are valid for the given
        # local time as an array. If you just want a single period, use
        # period_for_local instead and specify how ambiguities should be resolved.
        # Returns an empty array if no periods are found for the given time.
        def periods_for_local(local)
          local = local.to_ri_cal_date_time_value
          candidate_standard = last_before_local(standard, local)
          candidate_daylight = last_before_local(daylight, local)
          if candidate_daylight && candidate_daylight.swallows_local?(local, candidate_standard)
            []  # Invalid local time
          elsif candidate_standard
            if candidate_daylight
              if candidate_daylight.dtstart > candidate_standard.dtstart
                [candidate_daylight]
              elsif candidate_standard.ambiguous_local?(local)
                [candidate_daylight, candidate_standard]
              else
                [candidate_standard].compact
              end
            else
              [candidate_standard].compact
            end
          end
        end


        # Returns the TimezonePeriod for the given local time. local can either be
        # a DateTime, Time or integer timestamp (Time.to_i). Any timezone
        # information in local is ignored (it is treated as a time in the current
        # timezone).
        #
        # Warning: There are local times that have no equivalent UTC times (e.g.
        # in the transition from standard time to daylight savings time). There are
        # also local times that have more than one UTC equivalent (e.g. in the
        # transition from daylight savings time to standard time).
        #
        # In the first case (no equivalent UTC time), a PeriodNotFound exception
        # will be raised.
        #
        # In the second case (more than one equivalent UTC time), an AmbiguousTime
        # exception will be raised unless the optional dst parameter or block
        # handles the ambiguity.
        #
        # If the ambiguity is due to a transition from daylight savings time to
        # standard time, the dst parameter can be used to select whether the
        # daylight savings time or local time is used. For example,
        #
        #   Timezone.get('America/New_York').period_for_local(DateTime.new(2004,10,31,1,30,0))
        #
        # would raise an AmbiguousTime exception.
        #
        # Specifying dst=true would the daylight savings period from April to
        # October 2004. Specifying dst=false would return the standard period
        # from October 2004 to April 2005.
        #
        # If the dst parameter does not resolve the ambiguity, and a block is
        # specified, it is called. The block must take a single parameter - an
        # array of the periods that need to be resolved. The block can select and
        # return a single period or return nil or an empty array
        # to cause an AmbiguousTime exception to be raised.
        #
        # TODO: need to check for ambiguity
        def period_for_local(local, dst=nil)
          results = periods_for_local(local)

          if results.empty?
            raise TZInfo::PeriodNotFound
          elsif results.size < 2
            results.first
          else
            # ambiguous result try to resolve

            unless dst.nil?
              matches = results.find_all {|period| period.dst? == dst}
              results = matches unless matches.empty?
            end

            if results.size < 2
              results.first
            else
              # still ambiguous, try the block

              if block_given?
                results = yield results
              end

              if results.is_a?(TimezonePeriod)
                results
              elsif results && results.size == 1
                results.first
              else
                raise TZInfo::AmbiguousTime, "#{local} is an ambiguous local time."
              end
            end
          end
        end

        # convert time from utc time to this time zone
        def utc_to_local(time)
          time = time.to_ri_cal_date_time_value
          converted = time + period_for_utc(time).tzoffsetto_property
          converted.tzid = identifier
          converted
        end

        # convert time from this time zone to utc time
        def local_to_utc(time)
          time = time.to_ri_cal_date_time_value
          period = period_for_local(time)
          converted = time - period.tzoffsetto_property
          converted.tzid = "UTC"
          converted
        end
      end

      def self.entity_name #:nodoc:
        "VTIMEZONE"
      end

      def standard #:nodoc:
        @subcomponents["STANDARD"]
      end

      def daylight #:nodoc:
        @subcomponents["DAYLIGHT"]
      end

      def last_period(standard, daylight) #:nodoc:
        if standard
          if daylight
            standard.dtstart > daylight.dtstart ? standard : daylight
          else
            standard
          end
        else
          daylight
        end
      end

      def last_before_utc(period_array, time) #:nodoc:
        candidates = period_array.map {|period|
          period.last_before_utc(time)
        }
        result = candidates.max {|a, b| a.dtstart_property <=> b.dtstart_property}
        result
      end

      def last_before_local(period_array, time) #:nodoc:
        candidates = period_array.map {|period|
          period.last_before_local(time)
        }
        result = candidates.max {|a, b| a.dtstart_property <=> b.dtstart_property}
        result
      end
  end
end


