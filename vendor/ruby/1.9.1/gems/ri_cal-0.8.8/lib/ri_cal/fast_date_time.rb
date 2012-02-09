module RiCal
  #- ©2009 Rick DeNatale
  #- All rights reserved. Refer to the file README.txt for the license
  #
  # FastDateTime mimics the Ruby Standard library DateTime class but avoids the use of Rational
  # Instead of using a Rational for the utc offset, FastDateTime uses an integer seconds value
  class FastDateTime
    attr_accessor :date, :hour, :min, :sec, :offset, :secs_since_bod

    SECONDS_IN_A_DAY = 60*60*24 unless defined? SECONDS_IN_A_DAY

    include Comparable

    def initialize(year, month, day, hour, min, sec, offset_seconds)
      @date = Date.civil(year, month, day)
      @secs_since_bod = hms_to_seconds(hour, min, sec)
      @hour, @min, @sec, @offset = hour, min, sec, offset_seconds
    end

    def self.from_date_time(date_time)
      new(date_time.year, date_time.month, date_time.day, date_time.hour, date_time.min, date_time.sec, (date_time.offset * SECONDS_IN_A_DAY).to_i)
    end
    
    def self.from_time(time)
      new(time.year, time.month, time.day, time.hour, time.min, time.sec, (time.utc_offset.offset * SECONDS_IN_A_DAY))
    end
    
    def self.from_date(date)
      new(date.year, date.month, date.day, 0, 0, 0, 0)
    end
    
    def self.from_date_at_end_of_day(date)
      new(date.year, date.month, date.day, 23, 59, 59, 0)
    end

    alias_method :utc_offset_seconds, :offset

    def ical_str
      "%04d%02d%02dT%02d%02d%02d" % [year, month, day, hour, min, sec]
    end

    def ical_date_str
      "%04d%02d%02d" % [year, month, day]
    end

    def year
      @date.year
    end

    def month
      @date.month
    end

    alias_method :mon, :month

    def day
      @date.day
    end
    
    def wday
      @date.wday
    end

    def to_datetime
      DateTime.civil(year, month, day, hour, min, sec, RiCal.RationalOffset[utc_offset_seconds])
    end

    def ==(other)
      [date, secs_since_bod, offset] == [other.date, other.secs_since_bod, other.offset]
    end

    def <=> (other)
      if FastDateTime === other
        [date, secs_since_bod] <=> [other.date, other.secs_since_bod]
      else
        [year, month, day, hour, min, sec] <=> [other.year, other.month, other.day, other.hour, other.min, other.sec]
      end
    end

    def to_s
      "#{year}/#{month}/#{day} #{hour}:#{min}:#{sec} #{offset}"
    end

    # def jd
    #   date.jd
    # end
    # 
    def days_in_month
      date.days_in_month
    end

    alias_method :inspect, :to_s

    # Return a new FastDateTime based on the receiver but with changes specified by the options
    def change(options)
      FastDateTime.new(
      options[:year]  || year,
      options[:month] || month,
      options[:day]   || day,
      options[:hour]  || hour,
      options[:min]   || (options[:hour] ? 0 : min),
      options[:sec]   || ((options[:hour] || options[:min]) ? 0 : sec),
      options[:offset]  || offset
      )
    end

    # def new_offset(ofst)
    #   if ofst == offset
    #     self
    #   else
    #     advance(:seconds => offset - ofset, :offset => ofst)
    #   end
    # end

    def utc
      if offset == 0
        self
      else
        advance(:seconds => -offset, :offset => 0)
      end
    end

    def hms_to_seconds(hours, minutes, seconds)
      seconds + 60 *(minutes + (60 * hours))
    end

    def seconds_to_hms(total_seconds)
      sign = total_seconds <=> 0
      remaining = total_seconds.abs
      seconds = sign * (remaining % 60)
      remaining = remaining / 60
      minutes = sign * (remaining % 60)
      [remaining / 60, minutes, seconds]
    end

    def adjust_day_delta(day_delta, new_secs_since_bod)
      if new_secs_since_bod == 0
        [day_delta, new_secs_since_bod]
      elsif new_secs_since_bod > 0
        [day_delta + (new_secs_since_bod / SECONDS_IN_A_DAY), new_secs_since_bod % SECONDS_IN_A_DAY]
      else
        [day_delta - (1 + new_secs_since_bod.abs / SECONDS_IN_A_DAY), 
         SECONDS_IN_A_DAY - (new_secs_since_bod.abs % SECONDS_IN_A_DAY)]
      end
     end


    def advance(options) # :nodoc:
      new_date = @date
      new_offset = options[:offset] || offset
      month_delta = (options[:years] || 0) * 12 + (options[:months] || 0)
      day_delta =   (options[:weeks] || 0) * 7 + (options[:days] || 0)
      sec_delta = hms_to_seconds((options[:hours] || 0), (options[:minutes] || 0), (options[:seconds] || 0))
      day_delta, new_secs_since_bod = *adjust_day_delta(day_delta, secs_since_bod + sec_delta)
      new_hour, new_min, new_sec = *seconds_to_hms(new_secs_since_bod)
      new_date = new_date >> month_delta unless month_delta == 0
      new_date += day_delta unless day_delta == 0
      FastDateTime.new(new_date.year, new_date.month, new_date.day, new_hour, new_min, new_sec, new_offset)
    end

    # Determine the day which falls on a particular weekday of the same month as the receiver
    #
    # == Parameters
    # n:: the ordinal number being requested
    # which_wday:: the weekday using Ruby time conventions, i.e. 0 => Sunday, 1 => Monday, ...

    # e.g. to obtain the 3nd Tuesday of the receivers month use
    #
    #   time.nth_wday_in_month(2, 2)
    def nth_wday_in_month(n, which_wday)
      first_of_month = change(:day => 1)
      first_in_month = first_of_month.advance(:days => (which_wday - first_of_month.wday))
      first_in_month = first_in_month.advance(:days => 7) if first_in_month.month != first_of_month.month
      if n > 0
        first_in_month.advance(:days => (7*(n - 1)))
      else
        possible = first_in_month.advance(:days => 21)
        possible = possible.advance(:days => 7) while possible.month == first_in_month.month
        last_in_month = possible.advance(:days => - 7)
        (last_in_month.advance(:days => - (7*(n.abs - 1))))
      end
    end
    
    # Determine the equivalent time on the day which falls on a particular weekday of the same year as the receiver
    #
    # == Parameters
    # n:: the ordinal number being requested
    # which_wday:: the weekday using Ruby time conventions, i.e. 0 => Sunday, 1 => Monday, ...
    
    # e.g. to obtain the 2nd Monday of the receivers year use
    #
    #   time.nth_wday_in_year(2, 1)
    def nth_wday_in_year(n, which_wday)
      if n > 0
        first_of_year = change(:month => 1, :day => 1)
        first_in_year = first_of_year.advance(:days => (which_wday - first_of_year.wday + 7) % 7)
        first_in_year.advance(:days => (7*(n - 1)))
      else
        december25 = change(:month => 12, :day => 25)
        last_in_year = december25.advance(:days => (which_wday - december25.wday + 7) % 7)
        last_in_year.advance(:days => (7 * (n + 1)))
      end
    end


    # Return a DateTime which is the beginning of the first day on or before the receiver
    # with the specified wday
    def start_of_week_with_wkst(wkst)
      wkst ||= 1
      date = @date
      date -= 1 while date.wday != wkst
      date
    end
    
    def iso_weeks_in_year(wkst)
      @date.iso_weeks_in_year(wkst)
    end
    
    def iso_year_start(wkst)
      @date.iso_year_start(wkst)
    end
    
    def iso_year_and_week_one_start(wkst)
      @date.iso_year_and_week_one_start(wkst)
    end
    
    def cmp_fast_date_time_value(other)
      other <=> self
    end

    
  end

end