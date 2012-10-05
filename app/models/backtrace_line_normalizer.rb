class BacktraceLineNormalizer
  def initialize(raw_line)
    @raw_line = raw_line
  end

  def call
    @raw_line.merge 'file' => normalized_file, 'method' => normalized_method
  end

  private
  def normalized_file
    @raw_line['file'].blank? ? "[unknown source]" :  @raw_line['file'].to_s.gsub(/\[PROJECT_ROOT\]\/.*\/ruby\/[0-9.]+\/gems/, '[GEM_ROOT]/gems')
  end

  def normalized_method
    @raw_line['method'].gsub(/[0-9_]{10,}+/, "__FRAGMENT__")
  end

end
