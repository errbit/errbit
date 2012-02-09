module RiCal
  class PropertyValue
    class RecurrenceRule < PropertyValue
      #- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
      #
      module InitializationMethods # :nodoc:
        
        attr_reader :by_day_scope
        
        def add_to_options_hash(options_hash, key, value)
          options_hash[key] = value if value
          options_hash
        end
        
        def add_byrule_strings_to_options_hash(options_hash, key)
          if (rules = by_list[key])
            if rules.length == 1
              options_hash[key] = rules.first.source
            else
              options_hash[key] = rules.map {|rule| rule.source}
            end
          end
        end
        
        def to_options_hash
          options_hash = {:freq => freq, :interval => interval}
          options_hash[:params] = params unless params.empty?
          add_to_options_hash(options_hash, :count, @count)
          add_to_options_hash(options_hash, :until, @until)
          add_to_options_hash(options_hash, :interval, @interval)
          [:bysecond, :byminute, :byhour, :bymonth, :bysetpos].each do |bypart|
              add_to_options_hash(options_hash, bypart, by_list[bypart])
            end
          [:byday, :bymonthday, :byyearday, :byweekno].each do |bypart|
             add_byrule_strings_to_options_hash(options_hash, bypart)
          end
          options_hash
        end

        def initialize_from_value_part(part, dup_hash) # :nodoc:
          part_name, value = part.split("=")
          attribute = part_name.downcase
          errors << "Repeated rule part #{attribute} last occurrence was used" if dup_hash[attribute]
          case attribute
          when "freq"
            self.freq = value
          when "wkst"
            self.wkst = value
          when "until"
            @until = PropertyValue.date_or_date_time(self, :value => value)
          when "count"
            @count = value.to_i
          when "interval"
            self.interval = value.to_i
          when "bysecond", "byminute", "byhour", "bymonthday", "byyearday", "byweekno", "bymonth", "bysetpos"
            send("#{attribute}=", value.split(",").map {|int| int.to_i})
          when "byday"
            self.byday = value.split(",")
          else
            errors << "Invalid rule part #{part}"
          end
        end

        def by_list
          @by_list ||= {}
        end
        
        def calc_by_day_scope
          case freq
          when "YEARLY"
            scope = :yearly
          when "MONTHLY"
            scope = :monthly
          when "WEEKLY"
            scope = :weekly
          else
            scope = :daily
          end
          scope = :monthly if scope != :weekly && @by_list_hash[:bymonth]
          scope = :weekly if scope != :daily && @by_list_hash[:byweekno]
          @by_day_scope = scope
        end
        
        def bysecond=(val)
          @by_list_hash[:bysecond] = val
        end

        def byminute=(val)
          @by_list_hash[:byminute] = val
        end

        def byhour=(val)
          @by_list_hash[:byhour] = val
        end

        def bymonth=(val)
          @by_list_hash[:bymonth] = val
        end

        def bysetpos=(val)
          @by_list_hash[:bysetpos] = val
        end

        def byday=(val)
          @by_list_hash[:byday] = val
        end

        def bymonthday=(val)
          @by_list_hash[:bymonthday] = val
        end

        def byyearday=(val)
          @by_list_hash[:byyearday] = val
        end

        def byweekno=(val)
          @by_list_hash[:byweekno] = val
        end

        def init_by_lists
          [:bysecond,
            :byminute,
            :byhour,
            :bymonth,
            :bysetpos
            ].each do |which|
              if val = @by_list_hash[which]
                by_list[which] = [val].flatten.sort
              end
            end
            if val = @by_list_hash[:byday]
              byday_scope =  calc_by_day_scope 
              by_list[:byday] = [val].flatten.map {|day| RecurringDay.new(day, self, byday_scope)}
            end
            if val = @by_list_hash[:bymonthday]
              by_list[:bymonthday] = [val].flatten.map {|md| RecurringMonthDay.new(md)}
            end
            if val = @by_list_hash[:byyearday]
              by_list[:byyearday] = [val].flatten.map {|yd| RecurringYearDay.new(yd)}
            end
            if val = @by_list_hash[:byweekno]
              by_list[:byweekno] = [val].flatten.map {|wkno| RecurringNumberedWeek.new(wkno, self)}
            end
          end
        end
      end
    end
  end