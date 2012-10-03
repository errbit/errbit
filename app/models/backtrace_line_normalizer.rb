class BacktraceLineNormalizer
  def initialize(raw_line)
    @raw_line = raw_line
  end

  def call
    @raw_line.merge! 'file' => "[unknown source]" if @raw_line['file'].blank?
    @raw_line.merge! 'method' => @raw_line['method'].gsub(/[0-9_]{10,}+/, "__FRAGMENT__")
  end

end
