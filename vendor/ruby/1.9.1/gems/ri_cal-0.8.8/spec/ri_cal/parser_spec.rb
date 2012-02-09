#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. spec_helper])

describe RiCal::Parser do
  
  context ".separate_line" do
    it "should work" do
      RiCal::Parser.new.separate_line("DTSTART;TZID=America/New_York:20090804T120000").should == {
        :name => "DTSTART",
        :params => {"TZID" => "America/New_York"},
        :value => "20090804T120000"
        }
    end
  end
  
  context ".params_and_value" do
    it "should separate parameters and values" do
      RiCal::Parser.params_and_value(";TZID=(GMT-05.00) Eastern Time (US & Canada):20090804T120000").should == [{"TZID" => "(GMT-05.00) Eastern Time (US & Canada)"}, "20090804T120000"]
    end
    
    it "should strip surrounding quotes" do
      RiCal::Parser.params_and_value(";TZID=\"(GMT-05.00) Eastern Time (US & Canada)\":20090804T120000").should == [{"TZID" => "(GMT-05.00) Eastern Time (US & Canada)"}, "20090804T120000"]
    end
  end
  
  def self.describe_property(entity_name, prop_name, params, value, type = RiCal::PropertyValue::Text)
    describe_named_property(entity_name, prop_name, prop_name, params, value, false, type)
  end
    
  def self.describe_multi_property(entity_name, prop_name, params, value, type = RiCal::PropertyValue::Text)
    describe_named_property(entity_name, prop_name, prop_name, params, value, true, type)
  end
    
  def self.describe_named_property(entity_name, prop_text, prop_name, params, value, multi, type = RiCal::PropertyValue::Text)
    ruby_value_name = prop_name.tr("-", "_").downcase
    ruby_prop_name = "#{prop_text.tr('-', '_').downcase}_property"
    expected_ruby_value = type.convert(nil, value).ruby_value
    expected_params = {}
    params.each do |key, parm_value|
      # strip surrounding quotes from values
      expected_params[key] = parm_value.sub(/^\"(.*)\"$/, '\1')
    end
    
    describe "#{prop_name} with value of #{value.inspect}" do
      parse_input = params.inject("BEGIN:#{entity_name.upcase}\n#{prop_text.upcase}") { |pi, assoc| "#{pi};#{assoc[0]}=#{assoc[1]}"}
      parse_input = "#{parse_input}:#{value.to_rfc2445_string}\nEND:#{entity_name.upcase}"
      
      it "should parse an event with an #{prop_text.upcase} property" do
        lambda {RiCal::Parser.parse(StringIO.new(parse_input))}.should_not raise_error
      end

      describe "property characteristics" do
        before(:each) do
          @entity = RiCal::Parser.parse(StringIO.new(parse_input)).first
          @prop = @entity.send(ruby_prop_name.to_sym)
          if multi && Array === @prop
            @prop = @prop.first
          end
        end

        it "should be a #{type.name}" do
          @prop.class.should == type
        end

        it "should have the right value" do
          @prop.value.should == value
        end
        
        it "should make the value accessible directly" do
          val = @entity.send(ruby_value_name)
          val = val.first if multi && Array === val
          val.should == expected_ruby_value
        end

        it "should have the right parameters" do
          expected_params.each do | key, value |
            @prop.params[key].should == value
          end
        end
      end

    end
  end
  
  describe ".next_line" do
    it "should return line by line" do
      RiCal::Parser.new(StringIO.new("abc\ndef")).next_line.should == "abc"      
    end

    it "should combine lines" do
      RiCal::Parser.new(StringIO.new("abc\n def\n  ghi")).next_line.should == "abcdef ghi"      
    end
  end

  describe ".separate_line" do

    before(:each) do
      @parser = RiCal::Parser.new
    end

    it "should return a hash" do
      @parser.separate_line("abc;x=y;z=1,2:value").should be_kind_of(Hash)
    end

    it "should find the name" do
      @parser.separate_line("abc;x=y;z=1,2:value")[:name].should == "abc"
    end

    it "should find the parameters" do
      @parser.separate_line("abc;x=y;z=1,2:value")[:params].should == {"x" => "y","z" => "1,2"}
    end

    it "should find the value" do
      @parser.separate_line("abc;x=y;z=1,2:value")[:value].should == "value"
    end
  end

  describe ".parse" do

    it "should reject a file which doesn't start with BEGIN" do
      parser = RiCal::Parser.new(StringIO.new("END:VCALENDAR"))
      lambda {parser.parse}.should raise_error     
    end

    describe "parsing an event" do
      it "should parse an event" do
        parser = RiCal::Parser.new(StringIO.new("BEGIN:VEVENT"))
        RiCal::Component::Event.should_receive(:from_parser).with(parser, nil, "VEVENT")
        parser.parse
      end

      it "should parse an event and return a Event" do
        cal = RiCal::Parser.parse(StringIO.new("BEGIN:VEVENT\nEND:VEVENT")).first
        cal.should be_kind_of(RiCal::Component::Event)
      end

      #RFC 2445 section 4.8.1.1 pp 77
      describe_multi_property("VEVENT", "ATTACH", {"FMTTYPE" => "application/postscript"}, "FMTTYPE=application/postscript:ftp//xyzCorp.com/put/reports/r-960812.ps", RiCal::PropertyValue::Uri)

      #RFC 2445 section 4.8.1.2 pp 78
      describe_multi_property("VEVENT", "CATEGORIES", {"LANGUAGE" => "us-EN"}, "APPOINTMENT,EDUCATION", RiCal::PropertyValue::Array)

      #RFC 2445 section 4.8.1.3 pp 79
      describe_named_property("VEVENT", "CLASS", "security_class", {"X-FOO" => "BAR"}, "PUBLIC", false)

      #RFC 2445 section 4.8.1.4 pp 80
      describe_multi_property("VEVENT", "COMMENT", {"X-FOO" => "BAR"}, "Event comment")

      #RFC 2445 section 4.8.1.5 pp 81
      describe_property("VEVENT", "DESCRIPTION", {"X-FOO" => "BAR"}, "Event description")
      
      #RFC 2445 section 4.8.1.6 pp 82
      describe_property("VEVENT", "GEO", {"X-FOO" => "BAR"}, "37.386013;-122.082932", RiCal::PropertyValue::Geo)
      
      #RFC 2445 section 4.8.1.7 pp 84
      describe_property("VEVENT", "LOCATION", {"ALTREP" => "\"http://xyzcorp.com/conf-rooms/f123.vcf\""}, "Conference Room - F123, Bldg. 002")

      #Blank value with properties
      describe_property("VEVENT", "LOCATION", {"LANGUAGE" => "en-US"}, "")
      
      #RFC 2445 section 4.8.1.8 PERCENT-COMPLETE does not apply to Events
      
      #RFC 2445 section 4.8.1.9 pp 84
      describe_property("VEVENT", "PRIORITY", {"X-FOO" => "BAR"}, 1, RiCal::PropertyValue::Integer)

      #RFC 2445 section 4.8.1.10 pp 87
      describe_multi_property("VEVENT", "RESOURCES", {"X-FOO" => "BAR"}, "Easel,Projector,VCR", RiCal::PropertyValue::Array)

      #RFC 2445 section 4.8.1.11 pp 88
      describe_property("VEVENT", "STATUS", {"X-FOO" => "BAR"}, "CONFIRMED")

      #RFC 2445 section 4.8.1.12 pp 89
      describe_property("VEVENT", "SUMMARY", {"X-FOO" => "BAR"}, "Department Party")
      
      #RFC 2445 section 4.8.2.1 COMPLETED does not apply to Events
      
      #RFC 2445 section 4.8.2.2 DTEND p91
      describe_property("VEVENT", "DTEND", {"X-FOO" => "BAR"}, "19970714", RiCal::PropertyValue::Date)
      describe_property("VEVENT", "DTEND", {"X-FOO" => "BAR"}, "19970714T235959Z", RiCal::PropertyValue::DateTime)

      #RFC 2445 section 4.8.2.3 DUE does not apply to Events
      
      #RFC 2445 section 4.8.2.4 DTSTART p93
      describe_property("VEVENT", "DTSTART", {"X-FOO" => "BAR"}, "19970714", RiCal::PropertyValue::Date)
      describe_property("VEVENT", "DTSTART", {"X-FOO" => "BAR"}, "19970714T235959Z", RiCal::PropertyValue::DateTime)

      #RFC 2445 section 4.8.2.5 DURATION p94
      describe_property("VEVENT", "DURATION", {"X-FOO" => "BAR"}, "PT1H", RiCal::PropertyValue::Duration)

      #RFC 2445 section 4.8.2.6 FREEBUSY does not apply to Events
      
      #RFC 2445 section 4.8.2.4 TRANSP p93
      describe_property("VEVENT", "TRANSP", {"X-FOO" => "BAR"}, "OPAQUE")
      #TO-DO need to spec that values are constrained to OPAQUE and TRANSPARENT
      #      and that this property can be specified at most once
      
      #RFC 2445 section 4.8.4.1 ATTENDEE p102
      describe_multi_property("VEVENT", "ATTENDEE", {"X-FOO" => "BAR"}, "MAILTO:jane_doe@host.com", RiCal::PropertyValue::CalAddress)
      #TO-DO need to handle param values
      
      #RFC 2445 section 4.8.4.2 CONTACT p104
      describe_multi_property("VEVENT", "CONTACT", {"X-FOO" => "BAR"}, "Contact info")
      
      #RFC 2445 section 4.8.4.3 ORGANIZER p106
      describe_property("VEVENT", "ORGANIZER", {"X-FOO" => "BAR", "CN" => "John Smith"}, "MAILTO:jsmith@host1.com", RiCal::PropertyValue::CalAddress)
      #TO-DO need to handle param values     
      
      #RFC 2445 section 4.8.4.4 RECURRENCE-ID p107
      describe_property("VEVENT", "RECURRENCE-ID", {"X-FOO" => "BAR", "VALUE" => "DATE"}, "19970714", RiCal::PropertyValue::Date)
      describe_property("VEVENT", "RECURRENCE-ID", {"X-FOO" => "BAR", "VALUE" => "DATE-TIME"}, "19970714T235959Z", RiCal::PropertyValue::DateTime)
      #TO-DO need to handle parameters
      
      #RFC 2445 section 4.8.4.5 RELATED-TO p109
      describe_multi_property("VEVENT", "RELATED-TO", {"X-FOO" => "BAR"}, "<jsmith.part7.19960817T083000.xyzMail@host3.com")
      
      #RFC 2445 section 4.8.4.6 URL p110
      describe_property("VEVENT", "URL", {"X-FOO" => "BAR"}, "http://abc.com/pub/calendars/jsmith/mytime.ics", RiCal::PropertyValue::Uri)
      
      #RFC 2445 section 4.8.4.7 UID p111
      describe_property("VEVENT", "UID", {"X-FOO" => "BAR"}, "19960401T080045Z-4000F192713-0052@host1.com")
            
      #RFC 2445 section 4.8.5.1 EXDATE p112
      describe_multi_property("VEVENT", "EXDATE", {"X-FOO" => "BAR"}, "19960402T010000,19960403T010000,19960404T010000", RiCal::PropertyValue::OccurrenceList)

      #RFC 2445 section 4.8.5.2 EXRULE p114
      describe_multi_property("VEVENT", "EXRULE", {"X-FOO" => "BAR"}, "FREQ=DAILY;COUNT=10", RiCal::PropertyValue::RecurrenceRule)

      #RFC 2445 section 4.8.5.3 RDATE p115
      describe_multi_property("VEVENT", "RDATE", {"X-FOO" => "BAR"}, "19960402T010000,19960403T010000,19960404T010000", RiCal::PropertyValue::OccurrenceList)

      #RFC 2445 section 4.8.5.2 RRULE p117
      describe_multi_property("VEVENT", "RRULE", {"X-FOO" => "BAR"}, "FREQ=DAILY;COUNT=10", RiCal::PropertyValue::RecurrenceRule)

      #RFC 2445 section 4.8.7.1 CREATED p129
      describe_property("VEVENT", "CREATED", {"X-FOO" => "BAR"}, "19960329T133000Z", RiCal::PropertyValue::ZuluDateTime)
 
      #RFC 2445 section 4.8.7.2 DTSTAMP p129
      describe_property("VEVENT", "DTSTAMP", {"X-FOO" => "BAR"}, "19971210T080000Z", RiCal::PropertyValue::ZuluDateTime)

      #RFC 2445 section 4.8.7.3 LAST-MODIFIED p131
      describe_property("VEVENT", "LAST-MODIFIED", {"X-FOO" => "BAR"}, "19960817T133000Z", RiCal::PropertyValue::ZuluDateTime)

      #RFC 2445 section 4.8.7.3 SEQUENCE p131
      describe_property("VEVENT", "SEQUENCE", {"X-FOO" => "BAR"}, 2, RiCal::PropertyValue::Integer)

      #RFC 2445 section 4.8.8.2 REQUEST-STATUS p131
      describe_multi_property("VEVENT", "REQUEST-STATUS", {"X-FOO" => "BAR"}, "2.0;Success")
   end

    describe "parsing a calendar" do

      it "should parse a calendar" do
        parser = RiCal::Parser.new(StringIO.new("BEGIN:VCALENDAR"))
        RiCal::Component::Calendar.should_receive(:from_parser).with(parser, nil, "VCALENDAR")
        parser.parse
      end

      it "should parse a calendar and return an array of 1 Calendar" do
        cal = RiCal::Parser.parse(StringIO.new("BEGIN:VCALENDAR\nEND:VCALENDAR")).first
        cal.should be_kind_of(RiCal::Component::Calendar)
      end

      # RFC 2445, section 4.6 section 4.7.1, pp 73-74
      describe_property("VCALENDAR", "CALSCALE", {"X-FOO" => "Y"}, "GREGORIAN")

      # RFC 2445, section 4.6  section 4.7.2, pp 74-75
      describe_named_property("VCALENDAR", "METHOD", 'icalendar_method', {"X-FOO" => "Y"}, "REQUEST", false)

      # RFC 2445, section 4.6, pp 51-52, section 4.7.3, p 75-76
      describe_property("VCALENDAR", "PRODID", {"X-FOO" => "Y"}, "-//ABC CORPORATION//NONSGML/ My Product//EN")

      # RFC 2445, section 4.6, pp 51-52, section 4.7.3, p 75-76
      describe_property("VCALENDAR", "VERSION", {"X-FOO" => "Y"}, "2.0")


      # RFC2445 p 51
      it "should parse a calendar with an X property" do
        lambda {RiCal::Parser.parse(StringIO.new("BEGIN:VCALENDAR\nX-PROP;X-FOO=Y:BAR\nEND:VCALENDAR"))}.should_not raise_error
      end

      describe 'the X property' do
        before(:each) do
          @x_props = RiCal::Parser.parse(StringIO.new("BEGIN:VCALENDAR\nX-PROP;X-FOO=Y:BAR\nEND:VCALENDAR")).first.x_properties
          @x_prop = @x_props["X-PROP"]
        end
        
        it "should be an array of length 1" do
          @x_prop.should be_kind_of(Array)
          @x_prop.length.should == 1
        end

        it "should have a PropertyValue::Text element" do
          @x_prop.first.should be_kind_of(RiCal::PropertyValue::Text)
        end

        it "should have the right value" do
          @x_prop.first.value.should == "BAR"
        end

        it "should have the right parameters" do
          @x_prop.first.params.should == {"X-FOO" => "Y"}
        end
      end 
    end

    it "should parse a to-do" do
      parser = RiCal::Parser.new(StringIO.new("BEGIN:VTODO"))
      RiCal::Component::Todo.should_receive(:from_parser).with(parser, nil, "VTODO")
      parser.parse
    end

    it "should parse a journal entry" do
      parser = RiCal::Parser.new(StringIO.new("BEGIN:VJOURNAL"))
      RiCal::Component::Journal.should_receive(:from_parser).with(parser, nil, "VJOURNAL")
      parser.parse
    end

    it "should parse a free/busy component" do
      parser = RiCal::Parser.new(StringIO.new("BEGIN:VFREEBUSY"))
      RiCal::Component::Freebusy.should_receive(:from_parser).with(parser, nil, "VFREEBUSY")
      parser.parse
    end

    it "should parse a timezone component" do
      parser = RiCal::Parser.new(StringIO.new("BEGIN:VTIMEZONE"))
      RiCal::Component::Timezone.should_receive(:from_parser).with(parser, nil, "VTIMEZONE")
      parser.parse
    end

    it "should parse an alarm component" do
      parser = RiCal::Parser.new(StringIO.new("BEGIN:VALARM"))
      RiCal::Component::Alarm.should_receive(:from_parser).with(parser, nil, "VALARM")
      parser.parse
    end
  end
end
