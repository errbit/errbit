# frozen_string_literal: true

module Errbit
  class BacktraceDecorator < Draper::Decorator
    def lines
      @lines ||= (object.lines || []).map { |line| Errbit::BacktraceLineDecorator.new(line) }
    end

    def grouped_lines
      lines.chunk do |line|
        line.in_app? || false
      end
    end
  end
end
