class Subject
  def initialize(out=STDOUT)
    calendar_file = File.open(File.join(File.dirname(__FILE__), *%w[ical.ics]), 'r')
    @calendar = RiCal.parse(calendar_file).first
    @cutoff = Date.parse("20100531")
    @out = out
  end
  def run
    cutoff = @cutoff
    @calendar.events.each do |event|
      event.occurrences(:before => cutoff).each do |instance|
        @out.puts "Event #{instance.uid.slice(0..5)}, starting #{instance.dtstart}, ending #{instance.dtend}"
      end 
    end
  end
end