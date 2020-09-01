module AirbrakeApi
  module V3
    class SourceMapLine
      def initialize(source_map, generated_line)
        @source_map = source_map
        @generated_line = generated_line
      end

      def original_line
        source_mapping = source_map&.bsearch(SourceMap::Offset.new(generated_line['line'], generated_line['column']))
        {
          method: source_mapping ? source_mapping.name : generated_line['function'],
          file: source_mapping ? source_mapping.source : generated_line['file'],
          number: source_mapping ? source_mapping.original.line : generated_line['line'],
          column: source_mapping ? source_mapping.original.column : generated_line['column']
        }
      end

      private

      attr_reader :source_map, :generated_line
    end
  end
end
