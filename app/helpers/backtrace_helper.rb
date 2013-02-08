module BacktraceHelper
  # Group lines into sections of in-app files and external files
  # (An implementation of Enumerable#chunk so we don't break 1.8.7 support.)
  def grouped_lines(lines)
    line_groups = []
    lines.each do |line|
      in_app = line.in_app?
      if line_groups.last && line_groups.last[0] == in_app
        line_groups.last[1] << line
      else
        line_groups << [in_app, [line]]
      end
    end
    line_groups
  end
end
