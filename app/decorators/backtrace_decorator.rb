# frozen_string_literal: true

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
end
