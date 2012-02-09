#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib ri_cal]))
require 'cgi'
require 'tzinfo'


module Kernel
  if ENV.keys.find {|env_var| env_var.match(/^TM_/)}
    def rputs(*args)
      puts( *["<pre>", args.collect {|a| CGI.escapeHTML(a.to_s)}, "</pre>"])
    end
  else
    alias_method :rputs, :puts
  end
end

def date_time_with_zone(date_time, tzid = "US/Eastern")
  date_time.dup.set_tzid(tzid)
end

def dt_prop(date_time, tzid = "US/Eastern")
  RiCal::PropertyValue::DateTime.convert(nil, date_time_with_zone(date_time, tzid))
end

def offset_for_tzid(year, month, day, hour, min, sec, tzid, alternate)
  tz = TZInfo::Timezone.get(tzid) rescue nil
  if tz
    Rational(tz.period_for_local(DateTime.civil(year, month, day, hour, min, sec)).utc_total_offset, 86400)
  else
    provided_offset
  end
end

def rectify_ical(string)
  string.gsub(/^\s+/, "")
end

if RiCal::TimeWithZone
  def result_time_in_zone(year, month, day, hour, min, sec, tzid, alternate_offset = nil)
    DateTime.civil(year, month, day, hour, min, sec, 
       offset_for_tzid(year, month, day, hour, min, sec, tzid, alternate_offset)).in_time_zone(tzid)
  end
else
  def result_time_in_zone(year, month, day, hour, min, sec, tzid, alternate_offset = nil)
    DateTime.civil(year, month, day, hour, min, sec, 
    offset_for_tzid(year, month, day, hour, min, sec, tzid, alternate_offset)).set_tzid(tzid)
  end
end

