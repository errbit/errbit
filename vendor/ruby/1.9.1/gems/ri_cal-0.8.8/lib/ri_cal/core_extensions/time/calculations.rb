module RiCal
  module CoreExtensions #:nodoc:
    module Time #:nodoc:
      #- ©2009 Rick DeNatale
      #- All rights reserved. Refer to the file README.txt for the license
      #
      # Provide calculation methods for use by the RiCal gem
      # This module is included by Time, Date, and DateTime
      module Calculations
        # A predicate method used to determine if the receiver is within a leap year
        def leap_year?
          year % 4 == 0 && (year % 400 == 0 || year % 100 != 0)
        end 

        # Return the number of days in the month which includes the receiver
        def days_in_month
          raw = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][self.month]
          self.month == 2 && leap_year? ? raw + 1 : raw
        end

        # Return the date on which the first iso week with a given starting week day occurs
        # for a given iso year
        # 
        #
        # From RFC 2445 page 43:
        # A week is defined as a seven day period, starting on the day of the week defined to be the
        # week start (see WKST). Week number one of the calendar year is the first week which contains 
        # at least four (4) days in that calendar
        # year.
        #
        # == parameters
        # year:: the iso year
        # wkst:: an integer representing the day of the week on which weeks are deemed to start. This uses
        # the ruby convention where 0 represents Sunday.
        def self.iso_week_one(year, wkst)
          # 
          # Note that wkst uses the ruby definition, with Sunday = 0 
          #
          # A good article about calculating ISO week number is at
          # http://www.boyet.com/Articles/PublishedArticles/CalculatingtheISOweeknumb.html
          #
          # RFC 2445 generalizes the notion of ISO week by allowing the start of the week to vary.
          # In order to adopt the algorithm in the referenced article, we must determine, for each
          # wkst value, the day in January which must be contained in week 1 of the year.
          # 
          # For a given wkst week 1 for a year is the first week which
          #   1) Starts with a day with a wday of wkst
          #   2) Contains a majority (4 or more) of days in that year
          # 
          # If end of prior Dec, start of Jan          Week 1 starts on For WKST =

          # MO TU WE TH FR SA SU MO TU WE TH FR SA SU  MO    TU    WE    TH    FR    SA    SU      
          # 01 02 03 04 05 06 07 08 09 10 11 12 13 14 01-07 02-08 03-09 04-10 05-11 06-12 07-13
          # 31 01 02 03 04 05 06 07 08 09 10 11 12 13 31-06 01-07 02-08 03-09 04-10 05-11 06-12
          # 30 31 01 02 03 04 05 06 07 08 09 10 11 12 30-05 31-06 01-07 02-08 03-09 04-10 05-11
          # 29 30 31 01 02 03 04 05 06 07 08 09 10 11 29-04 30-05 31-06 01-07 02-08 03-09 04-10
          # 28 29 30 31 01 02 03 04 05 06 07 08 09 10 04-10 29-04 30-05 31-06 01-07 02-08 03-09
          # 27 28 29 30 31 01 02 03 04 05 06 07 08 09 03-09 04-10 29-04 30-05 31-06 01-07 02-08
          # 26 27 28 29 30 31 01 02 03 04 05 06 07 08 02-08 03-09 04-10 29-04 30-05 31-06 01-07
          # 25 26 27 28 29 30 31 01 02 03 04 05 06 07 01-07 02-08 03-09 04-10 29-04 30-05 31-06
          #                     Week 1 must contain     4     4     4     4     ?     ?     ?  
          #
          # So for a wkst of FR, SA, or SU, there is no date which MUST be contained in the 1st week
          # We'll have to brute force that
          if (1..4).include?(wkst)
            # return the date of the wkst day which is less than or equal to jan4th
            jan4th = ::Date.new(year, 1, 4)
            result = jan4th - (convert_wday(jan4th.wday) - convert_wday(wkst))
          else
            # return the date of the wkst day which is greater than or equal to Dec 31 of the prior year
            dec29th = ::Date.new(year-1, 12, 29)
            result = dec29th + convert_wday(wkst) - convert_wday(dec29th.wday)
          end
          result
        end

        # Convert the receivers wday to RFC 2445 format.  Whereas the Ruby time/date classes use
        # 0 to represent Sunday, RFC 2445 uses 7.
        def self.convert_wday(wday)
          wday == 0 ? 7 : wday
        end

        # Return an array containing the iso year and iso week number for the receiver.
        # Note that the iso year may be the year before or after the calendar year containing the receiver.
        # == parameter
        # wkst:: an integer representing the day of the week on which weeks are deemed to start. This uses
        # the ruby convention where 0 represents Sunday.
        def iso_year_and_week_one_start(wkst)
          iso_year = self.year
          date = ::Date.new(self.year, self.month, self.mday)
          if (date >= ::Date.new(iso_year, 12, 29))
            week_one_start =  Calculations.iso_week_one(iso_year + 1, wkst)
            if date < week_one_start
              week_one_start = Calculations.iso_week_one(iso_year, wkst)
            else
              iso_year += 1
            end
          else
            week_one_start = Calculations.iso_week_one(iso_year, wkst)
            if (date < week_one_start)
              iso_year -= 1
              week_one_start = Calculations.iso_week_one(iso_year, wkst)
            end
          end
          [iso_year, week_one_start]
        end

        def iso_year_and_week_num(wkst) #:nodoc:
          iso_year, week_one_start = *iso_year_and_week_one_start(wkst)
          [iso_year, (::Date.new(self.year, self.month, self.mday) - week_one_start).to_i / 7 + 1]
        end

        # return the number of weeks in the the iso year containing the receiver
        # == parameter
        # wkst:: an integer representing the day of the week on which weeks are deemed to start. This uses
        # the ruby convention where 0 represents Sunday.
        def iso_weeks_in_year(wkst)
          iso_year, week_one_start = *iso_year_and_week_one_start(wkst)
          probe_date = week_one_start + (7*52)
          if probe_date.iso_year(wkst) == iso_year
            53
          else
            52
          end
        end

        # return the iso week number of the receiver
        # == parameter
        # wkst:: an integer representing the day of the week on which weeks are deemed to start. This uses
        # the ruby convention where 0 represents Sunday.
        def iso_week_num(wkst)
          iso_year_and_week_num(wkst)[1]
        end

        # return the iso year of the receiver
        # == parameter
        # wkst:: an integer representing the day of the week on which weeks are deemed to start. This uses
        # the ruby convention where 0 represents Sunday.
        def iso_year(wkst)
          iso_year_and_week_num(wkst)[0]
        end
        
        # return the first day of the iso year of the receiver
        # == parameter
        # wkst:: an integer representing the day of the week on which weeks are deemed to start. This uses
        # the ruby convention where 0 represents Sunday.
        def iso_year_start(wkst)
          iso_year_and_week_one_start(wkst)[1]
        end
      end
    end
  end
end