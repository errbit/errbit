class BacktraceDecorator < Draper::Decorator
  def lines
    @lines ||= object.lines.map { |line| BacktraceLineDecorator.new line }
  end
end
