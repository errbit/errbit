class BacktraceDecorator < Draper::Decorator
  def lines
    @lines ||= (object.lines || []).map { |line| BacktraceLineDecorator.new line }
  end

  # Group lines into sections of in-app files and external files
  def grouped_lines
    lines.chunk do |line|
      line.in_app? || false
    end
  end

  def in_app_numbers_to_relative_file_paths
    new_map = {}
    lines.each do |line|
      new_map[line.file_relative] = line.number if line.in_app?
    end
    new_map
  end
end
