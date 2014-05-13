class BacktraceLineNormalizer

  def initialize(raw_line)
    @raw_line = raw_line || {}
  end

  def call
    @raw_line.merge "file" => normalized_file, "method" => normalized_method
  end

private

  def normalized_file
    return "[unknown source]" if @raw_line["file"].blank?

    @raw_line["file"].to_s
      .gsub(/\[PROJECT_ROOT\]\/.*\/ruby\/[0-9.]+\/gems/, "[GEM_ROOT]/gems") # Detect lines from gem
      .gsub(/\?[^\?]*$/, "") # Strip any query strings
  end

  def normalized_method
    return "[unknown method]" if @raw_line["method"].blank?

    @raw_line["method"].to_s
      .gsub(/[0-9_]{10,}+/, "__FRAGMENT__")
  end

end
