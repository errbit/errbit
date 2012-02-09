require 'tzinfo'


class Subject
  def initialize(out=STDOUT)
    @event = RiCal.Event do |e|
      e.dtstart = "TZID=America/New_York:19970929T090000"
      e.rrule = "FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-2"
    end
  end
  
  def run
    @event.occurrences(:count => 7)
  end
end