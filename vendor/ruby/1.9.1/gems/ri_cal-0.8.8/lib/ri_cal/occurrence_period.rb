module RiCal
  class OccurrencePeriod
    attr_reader :dtstart, :dtend
    def initialize(dtstart, dtend)
      @dtstart = dtstart
      @dtend = dtend
    end
    
    def to_s
      "op:#{dtstart}-#{dtend}"
    end
    
    def <=>(other)
      [dtstart, dtend] <=> [other.dtstart, other.dtend]
    end
  end
end