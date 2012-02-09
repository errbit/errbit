# encoding: utf-8
#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. spec_helper.rb])

def mock_enumerator(name, next_occurrence)
  mock(name, :next_occurrence => next_occurrence, :bounded? => true, :empty? => false)
end

# Note that this is more of a functional spec
describe RiCal::OccurrenceEnumerator do

  Fr13Unbounded_Zulu = <<-TEXT
BEGIN:VEVENT
DTSTART:19970902T090000Z
DTEND: 19970902T100000Z
EXDATE:19970902T090000Z
RRULE:FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13
END:VEVENT
TEXT

 Fr13Unbounded_Eastern = <<-TEXT
BEGIN:VEVENT
DTSTART;TZID=US-Eastern:19970902T090000
DTEND;TZID=US-Eastern:19970902T100000
EXDATE;TZID=US-Eastern:19970902T090000
RRULE:FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13
END:VEVENT
TEXT

 Fr13UnboundedZuluExpectedFive = [
   "19980213T090000Z",
   "19980313T090000Z",
   "19981113T090000Z",
   "19990813T090000Z",
   "20001013T090000Z" 
   ].map {|start| src = <<-TEXT
BEGIN:VEVENT
DTSTART:#{start}
DTEND:#{start.gsub("T09","T10")}
RECURRENCE-ID:#{start}
END:VEVENT
TEXT
          RiCal.parse_string(src).first
        }

  describe ".occurrences" do
    describe "with an unbounded component" do
      before(:each) do
        @it = RiCal.parse_string(Fr13Unbounded_Zulu).first
      end

      it "should raise an ArgumentError with no options to limit result" do
        lambda {@it.occurrences}.should raise_error(ArgumentError)
      end

      it "should have the right five occurrences when :count => 5 option is used" do
        result = @it.occurrences(:count => 5)
        result.should == Fr13UnboundedZuluExpectedFive
      end

      describe "with :starting specified" do
        it "should exclude dates before :starting" do
          result = @it.occurrences(:starting => Fr13UnboundedZuluExpectedFive[1].dtstart,
          :before   => Fr13UnboundedZuluExpectedFive[-1].dtstart)
          result.map{|o|o.dtstart}.should == Fr13UnboundedZuluExpectedFive[1..-2].map{|e| e.dtstart}
        end
      end

      describe "with :before specified" do
        it "should exclude dates after :before" do
          result = @it.occurrences(:before => Fr13UnboundedZuluExpectedFive[3].dtstart,
          :count => 5)
          result.map{|o|o.dtstart}.should == Fr13UnboundedZuluExpectedFive[0..2].map{|e| e.dtstart}
        end
      end
      
      describe "with :overlapping specified" do
        it "should include occurrences which overlap" do
          result = @it.occurrences(:overlapping => 
          [DateTime.parse("19981113T093000Z"), # occurrence[2].dtstart + 1/2 hour
           DateTime.parse("20001013T083000Z")]) # occurrence[4].dtstart - 1/2 hour
          result.map{|o|o.dtstart}.should == Fr13UnboundedZuluExpectedFive[2..3].map{|e| e.dtstart}
        end
      end
    end

    describe "for a non-recurring event" do
      before(:each) do
        @event_start = Time.now.utc
        @event = RiCal.Event do |event|
          event.dtstart = @event_start
          event.dtend   = @event_start + 3600
          # event.rrule  (no recurrence, single event)
        end
      end

      it "should enumerate no occurrences if dtstart is before :starting" do
        @event.occurrences(:starting => @event_start + 1).should be_empty
      end

      it "should enumerate no occurrences if dtstart is after :before" do
        @event.occurrences(:before => @event_start - 1).should be_empty
      end
      
      #Bug reported by K.J. Wierenga
      it "should not raise a NoMethodError when specifying just the :count option" do
        lambda {
          @event.occurrences(:count => 1)
          }.should_not raise_error
        end
      end
    end

  describe ".each" do
    describe " for Every Friday the 13th, forever" do
      before(:each) do
        event = RiCal.parse_string(Fr13Unbounded_Zulu).first
        @result = []
        event.each do |occurrence|
          break if @result.length >= 5
          @result << occurrence
        end
      end

      it "should have the right first six occurrences" do
        # TODO - Need to properly deal with timezones
        @result.should == Fr13UnboundedZuluExpectedFive
      end

    end
  end

  describe "#zulu_occurrence_range" do
    context "For an unbounded recurring event" do
      before(:each) do
        @event = RiCal.Event do |e|
          e.dtstart = "TZID=America/New_York:20090525T143500"
          e.dtend = "TZID=America/New_York:20090525T153500"
          e.add_rrule("FREQ=DAILY")
        end
      end

      it "should not be bounded" do
        @event.should_not be_bounded
      end

      it "should return an array with the first dtstart and nil" do
        @event.zulu_occurrence_range.should == [DateTime.civil(2009,5,25,18,35,00, 0), nil]
      end
    end

    context "For a bounded recurring event" do
      before(:each) do
        @event = RiCal.Event do |e|
          e.dtstart = "TZID=America/New_York:20090525T143500"
          e.dtend = "TZID=America/New_York:20090525T153500"
          e.add_rrule("FREQ=DAILY;COUNT=3")
        end
      end

      it "should return an array with the first dtstart last dtend converted to utc" do
        @event.zulu_occurrence_range.should == [DateTime.civil(2009,5,25,18,35,00, 0), DateTime.civil(2009,5,27,19,35,00, 0)]
      end
    end

    context "For an event with no recurrence rules" do
      context "with a non-floating dtstart and dtend" do
        before(:each) do
          @event = RiCal.Event do |e|
            e.dtstart = "TZID=America/New_York:20090525T143500"
            e.dtend = "TZID=America/New_York:20090525T153500"
          end
        end

        it "should return an array with dtstart and dtend converted to zulu time" do
          @event.zulu_occurrence_range.should == [DateTime.civil(2009,5,25,18,35,00, 0), DateTime.civil(2009,5,25,19,35,00, 0)]
        end
      end
      context "with a floating dtstart and dtend" do
        before(:each) do
          @event = RiCal.Event do |e|
            e.dtstart = "20090525T143500"
            e.dtend = "20090525T153500"
          end
        end

        it "should return an array with dtstart in the first timezone and dtend in the last time zone converted to zulu time" do
          @event.zulu_occurrence_range.should == [DateTime.civil(2009,5,25,2,35,00, 0), DateTime.civil(2009,5,26,3,35,00, 0)]
        end
      end
    end
  end

  context "Ticket #4 from paulsm" do
    it "should produce 4 occurrences" do
      cal = RiCal.parse_string rectify_ical(<<-ENDCAL)
      BEGIN:VCALENDAR
      METHOD:PUBLISH
      PRODID:-//Apple Inc.//iCal 3.0//EN
      CALSCALE:GREGORIAN
      X-WR-CALNAME:Australian32Holidays
      X-WR-CALDESC:Australian Public Holidays. Compiled from http://www.indust
      rialrelations.nsw.gov.au/holidays/default.html and the links for the oth
      er states at the bottom of that page
      X-WR-RELCALID:AC1E4CE8-6690-49F6-A144-2F8891DFFD8D
      VERSION:2.0
      X-WR-TIMEZONE:Australia/Sydney
      BEGIN:VEVENT
      SEQUENCE:8
      TRANSP:OPAQUE
      UID:5B5579F3-2137-11D7-B491-00039301B0C2
      DTSTART;VALUE=DATE:20020520
      DTSTAMP:20060602T045619Z
      SUMMARY:Adelaide Cup Carnival and Volunteers Day (SA)
      EXDATE;VALUE=DATE:20060515
      CREATED:20080916T000924Z
      DTEND;VALUE=DATE:20020521
      RRULE:FREQ=YEARLY;INTERVAL=1;UNTIL=20070520;BYMONTH=5;BYDAY=3MO
      END:VEVENT
      END:VCALENDAR
      ENDCAL
      cal.first.events.first.occurrences.length.should == 4
    end
  end

  context "Ticket #2 from paulsm" do
    before(:each) do
      cals = RiCal.parse_string rectify_ical(<<-ENDCAL)
      BEGIN:VCALENDAR
      X-WR-TIMEZONE:America/New_York
      PRODID:-//Apple Inc.//iCal 3.0//EN
      CALSCALE:GREGORIAN
      X-WR-CALNAME:test
      VERSION:2.0
      X-WR-RELCALID:1884C7F8-BC8E-457F-94AC-297871967D5E
      X-APPLE-CALENDAR-COLOR:#2CA10B
      BEGIN:VTIMEZONE
      TZID:US/Eastern
      BEGIN:DAYLIGHT
      TZOFFSETFROM:-0500
      TZOFFSETTO:-0400
      DTSTART:20070311T020000
      RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=2SU
      TZNAME:EDT
      END:DAYLIGHT
      BEGIN:STANDARD
      TZOFFSETFROM:-0400
      TZOFFSETTO:-0500
      DTSTART:20071104T020000
      RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=1SU
      TZNAME:EST
      END:STANDARD
      END:VTIMEZONE
      BEGIN:VEVENT
      SEQUENCE:5
      TRANSP:OPAQUE
      UID:00481E53-9258-4EA7-9F8D-947D3041A3F2
      DTSTART;TZID=US/Eastern:20090224T090000
      DTSTAMP:20090225T000908Z
      SUMMARY:Test Event
      CREATED:20090225T000839Z
      DTEND;TZID=US/Eastern:20090224T100000
      RRULE:FREQ=DAILY;INTERVAL=1;UNTIL=20090228T045959Z
      END:VEVENT
      END:VCALENDAR
      ENDCAL
      @event = cals.first.events.first
    end


    it "the event should be enumerable" do
      lambda {@event.occurrences}.should_not raise_error
    end
  end

  context "Lighthouse bug #3" do
    before(:each) do
      cals = RiCal.parse_string rectify_ical(<<-ENDCAL)
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//Mozilla.org/NONSGML Mozilla Calendar V1.1//EN
      BEGIN:VTIMEZONE
      TZID:/mozilla.org/20070129_1/Europe/Paris
      X-LIC-LOCATION:Europe/Paris
      BEGIN:DAYLIGHT
      TZOFFSETFROM:+0100
      TZOFFSETTO:+0200
      TZNAME:CEST
      DTSTART:19700329T020000
      RRULE:FREQ=YEARLY;INTERVAL=1;BYDAY=-1SU;BYMONTH=3
      END:DAYLIGHT
      BEGIN:STANDARD
      TZOFFSETFROM:+0200
      TZOFFSETTO:+0100
      TZNAME:CET
      DTSTART:19701025T030000
      RRULE:FREQ=YEARLY;INTERVAL=1;BYDAY=-1SU;BYMONTH=10
      END:STANDARD
      END:VTIMEZONE
      BEGIN:VEVENT
      CREATED:20070606T141629Z
      LAST-MODIFIED:20070606T154611Z
      DTSTAMP:20070607T120859Z
      UID:5d1ae55f-3910-4de9-8b65-d652768fb2f2
      SUMMARY:Lundi de Pâques
      DTSTART;VALUE=DATE;TZID=/mozilla.org/20070129_1/Europe/Paris:20070409
      DTEND;VALUE=DATE;TZID=/mozilla.org/20070129_1/Europe/Paris:20070410
      CATEGORIES:Jours fériés
      END:VEVENT
      END:VCALENDAR
      ENDCAL
      @event = cals.first.events.first
    end

      it "should be able to enumerate occurrences" do
        @event.occurrences.should == [@event]
      end
    end

    context "An event with a DATE dtstart, Ticket #6" do
      before(:each) do
        cal = RiCal.parse_string rectify_ical(<<-ENDCAL)
        BEGIN:VCALENDAR
        PRODID:-//Mozilla.org/NONSGML Mozilla Calendar V1.1//EN
        VERSION:2.0
        BEGIN:VEVENT
        CREATED:20090520T092032Z
        LAST-MODIFIED:20090520T092052Z
        DTSTAMP:20090520T092032Z
        UID:d41c124a-65c3-400e-bd04-1d2ee7b98352
        SUMMARY:event2
        RRULE:FREQ=MONTHLY;INTERVAL=1
        DTSTART;VALUE=DATE:20090603
        DTEND;VALUE=DATE:20090604
        TRANSP:TRANSPARENT
        END:VEVENT
        END:VCALENDAR
        ENDCAL
        @occurrences = cal.first.events.first.occurrences(
        :after => Date.parse('01/01/1990'),
        :before => Date.parse("01/01/2010")
        )
      end

      it "should produce the right dtstart values" do
        @occurrences.map {|o| o.dtstart}.should == [
          Date.parse("2009-06-03"),
          Date.parse("2009-07-03"),
          Date.parse("2009-08-03"),
          Date.parse("2009-09-03"),
          Date.parse("2009-10-03"),
          Date.parse("2009-11-03"),
          Date.parse("2009-12-03")
        ]
      end

      it "should produce events whose dtstarts are all dates" do
        @occurrences.all? {|o| o.dtstart.class == ::Date}.should be_true
      end

      it "should produce the right dtend values" do
        @occurrences.map {|o| o.dtend}.should == [
          Date.parse("2009-06-04"),
          Date.parse("2009-07-04"),
          Date.parse("2009-08-04"),
          Date.parse("2009-09-04"),
          Date.parse("2009-10-04"),
          Date.parse("2009-11-04"),
          Date.parse("2009-12-04")
        ]
      end

      it "should produce events whose dtstends are all dates" do
        @occurrences.all? {|o| o.dtend.class == ::Date}.should be_true
      end
    end
    context "bounded? bug" do
      before(:each) do
        events = RiCal.parse_string rectify_ical(<<-ENDCAL)
        BEGIN:VEVENT
        EXDATE:20090114T163000
        EXDATE:20090128T163000
        EXDATE:20090121T163000
        EXDATE:20090211T163000
        EXDATE:20090204T163000
        EXDATE:20090218T163000
        TRANSP:OPAQUE
        DTSTAMP;VALUE=DATE-TIME:20090107T024340Z
        CREATED;VALUE=DATE-TIME:20090107T024012Z
        DTEND;TZID=US/Mountain;VALUE=DATE-TIME:20090114T180000
        DTSTART;TZID=US/Mountain;VALUE=DATE-TIME:20090114T163000
        UID:15208112-E0FA-4A7C-954C-CFDF19D1B0E7
        RRULE:FREQ=WEEKLY;INTERVAL=1;UNTIL=20090219T065959Z
        SUMMARY:Wild Rose XC/Skate Training Series
        SEQUENCE:11
        LOCATION:Mountain Dell Golf Course
        END:VEVENT
        ENDCAL
        @event = events.first
      end

      it "should be able to enumerate occurrences" do
        @event.should be_bounded
      end
    end

    context "EXDATES with timezones bug" do
      before(:each) do
        cals = RiCal.parse_string rectify_ical(<<-ENDCAL)
        BEGIN:VCALENDAR
        METHOD:PUBLISH
        PRODID:-//Apple Inc.//iCal 3.0//EN
        CALSCALE:GREGORIAN
        X-WR-CALNAME:Utah Cycling
        X-WR-RELCALID:BF579011-36BF-49C6-8C7D-E96F03DE8055
        VERSION:2.0
        X-WR-TIMEZONE:US/Mountain
        BEGIN:VTIMEZONE
        TZID:US/Mountain
        BEGIN:DAYLIGHT
        TZOFFSETFROM:-0700
        TZOFFSETTO:-0600
        DTSTART:20070311T020000
        RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=2SU
        TZNAME:MDT
        END:DAYLIGHT
        BEGIN:STANDARD
        TZOFFSETFROM:-0600
        TZOFFSETTO:-0700
        DTSTART:20071104T020000
        RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=1SU
        TZNAME:MST
        END:STANDARD
        END:VTIMEZONE
        BEGIN:VEVENT
        SEQUENCE:11
        TRANSP:OPAQUE
        UID:15208112-E0FA-4A7C-954C-CFDF19D1B0E7
        DTSTART;TZID=US/Mountain:20090114T163000
        DTSTAMP:20090107T024340Z
        SUMMARY:Wild Rose XC/Skate Training Series
        EXDATE;TZID=US/Mountain:20090114T163000
        EXDATE;TZID=US/Mountain:20090128T163000
        EXDATE;TZID=US/Mountain:20090121T163000
        EXDATE;TZID=US/Mountain:20090211T163000
        EXDATE;TZID=US/Mountain:20090204T163000
        EXDATE;TZID=US/Mountain:20090218T163000
        CREATED:20090107T024012Z
        DTEND;TZID=US/Mountain:20090114T180000
        LOCATION:Mountain Dell Golf Course
        RRULE:FREQ=WEEKLY;INTERVAL=1;UNTIL=20090219T065959Z
        END:VEVENT
        END:VCALENDAR
        ENDCAL
        @event = cals.first.events.first
      end

      it "should have no occurrences" do
        @event.occurrences.length.should == 0
      end
    end
end

describe RiCal::OccurrenceEnumerator::OccurrenceMerger do
  before(:each) do
    @merger = RiCal::OccurrenceEnumerator::OccurrenceMerger
  end

  describe ".for" do
    it "should return an EmptyEnumerator if the rules parameter is nil" do
      @merger.for(nil, nil).should == RiCal::OccurrenceEnumerator::EmptyRulesEnumerator
    end

    it "should return an EmptyEnumerator if the rules parameter is empty" do
      @merger.for(nil, []).should == RiCal::OccurrenceEnumerator::EmptyRulesEnumerator
    end

    describe "with a single rrule" do
      before(:each) do
        @component = mock("component", :dtstart => :dtstart_value)
        @rrule = mock("rrule", :enumerator => :rrule_enumerator)
      end

      it "should return the enumerator the rrule" do
        @merger.for(@component, [@rrule]).should == :rrule_enumerator
      end

      it "should pass the component to the enumerator instantiation" do
        @rrule.should_receive(:enumerator).with(@component)
        @merger.for(@component, [@rrule])
      end
    end

    describe "with multiple rrules" do
      before(:each) do
        @component = mock("component", :dtstart => :dtstart_value)
        @enum1 = mock_enumerator("rrule_enumerator1", :occ1)
        @enum2 = mock_enumerator("rrule_enumerator2", :occ2)
        @rrule1 = mock("rrule", :enumerator => @enum1)
        @rrule2 = mock("rrule", :enumerator => @enum2)
      end

      it "should return an instance of RiCal::OccurrenceEnumerator::OccurrenceMerger" do
        @merger.for(@component, [@rrule1, @rrule2]).should be_kind_of(RiCal::OccurrenceEnumerator::OccurrenceMerger)
      end

      it "should pass the component to the enumerator instantiation" do
        @rrule1.should_receive(:enumerator).with(@component).and_return(@enum1)
        @rrule2.should_receive(:enumerator).with(@component).and_return(@enum2)
        @merger.for(@component, [@rrule1, @rrule2])
      end

      it "should preload the next occurrences" do
        @enum1.should_receive(:next_occurrence).and_return(:occ1)
        @enum2.should_receive(:next_occurrence).and_return(:occ2)
        @merger.for(@component, [@rrule1, @rrule2])
      end
    end
  end

  describe "#zulu_occurrence_range" do
  end

  describe "#next_occurence" do

    describe "with unique nexts" do
      before(:each) do
        @enum1 = mock_enumerator("rrule_enumerator1",3)
        @enum2 = mock_enumerator("rrule_enumerator2", 2)
        @rrule1 = mock("rrule", :enumerator => @enum1)
        @rrule2 = mock("rrule", :enumerator => @enum2)
        @it = @merger.new(0, [@rrule1, @rrule2])
      end

      it "should return the earliest occurrence" do
        @it.next_occurrence.should == 2
      end

      it "should advance the enumerator which returned the result" do
        @enum2.should_receive(:next_occurrence).and_return(4)
        @it.next_occurrence
      end

      it "should not advance the other enumerator" do
        @enum1.should_not_receive(:next_occurrence)
        @it.next_occurrence
      end

      it "should properly update the next array" do
        @enum2.stub!(:next_occurrence).and_return(4)
        @it.next_occurrence
        @it.nexts.should == [3, 4]
      end
    end

    describe "with duplicated nexts" do
      before(:each) do
        @enum1 = mock_enumerator("rrule_enumerator1", 2)
        @enum2 = mock_enumerator("rrule_enumerator2", 2)
        @rrule1 = mock("rrule", :enumerator => @enum1)
        @rrule2 = mock("rrule", :enumerator => @enum2)
        @it = @merger.new(0, [@rrule1, @rrule2])
      end

      it "should return the earliest occurrence" do
        @it.next_occurrence.should == 2
      end

      it "should advance both enumerators" do
        @enum1.should_receive(:next_occurrence).and_return(5)
        @enum2.should_receive(:next_occurrence).and_return(4)
        @it.next_occurrence
      end

      it "should properly update the next array" do
        @enum1.stub!(:next_occurrence).and_return(5)
        @enum2.stub!(:next_occurrence).and_return(4)
        @it.next_occurrence
        @it.nexts.should == [5, 4]
      end

    end

    describe "with all enumerators at end" do
      before(:each) do
        @enum1 = mock_enumerator("rrule_enumerator1", nil)
        @enum2 = mock_enumerator("rrule_enumerator2", nil)
        @rrule1 = mock("rrule", :enumerator => @enum1)
        @rrule2 = mock("rrule", :enumerator => @enum2)
        @it = @merger.new(0, [@rrule1, @rrule2])
      end

      it "should return nil" do
        @it.next_occurrence.should == nil
      end

      it "should not advance the enumerators which returned the result" do
        @enum1.should_not_receive(:next_occurrence)
        @enum2.should_not_receive(:next_occurrence)
        @it.next_occurrence
      end
    end
  end






end