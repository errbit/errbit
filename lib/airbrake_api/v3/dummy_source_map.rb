module AirbrakeApi
  module V3
    class DummySourceMap
      def original_line(generated_line)
        {
          method: generated_line['function'],
          file: generated_line['file'],
          number: generated_line['line'],
          column: generated_line['column']
        }
      end

      def data
        {}
      end
    end
  end
end
