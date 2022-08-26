module HoptoadNotifier
  # Front end to parsing the backtrace for each notice
  class Backtrace

    # Handles backtrace parsing line by line
    class Line

      # regexp (optionnally allowing leading X: for windows support)
      INPUT_FORMAT = %r{^((?:[a-zA-Z]:)?[^:]+):(\d+)(?::in `([^']+)')?$}.freeze

      # The file portion of the line (such as app/models/user.rb)
      attr_reader :file

      # The line number portion of the line
      attr_reader :number

      # The method of the line (such as index)
      attr_reader :method

      # Parses a single line of a given backtrace
      # @param [String] unparsed_line The raw line from +caller+ or some backtrace
      # @return [Line] The parsed backtrace line
      def self.parse(unparsed_line)
        _, file, number, method = unparsed_line.match(INPUT_FORMAT).to_a
        new(file, number, method)
      end

      def initialize(file, number, method)
        self.file   = file
        self.number = number
        self.method = method
      end

      # Reconstructs the line in a readable fashion
      def to_s
        "#{file}:#{number}:in `#{method}'"
      end

      def ==(other)
        to_s == other.to_s
      end

      def inspect
        "<Line:#{to_s}>"
      end

      private

      attr_writer :file, :number, :method
    end

    # holder for an Array of Backtrace::Line instances
    attr_reader :lines

    def self.parse(ruby_backtrace, opts = {})
      ruby_lines = split_multiline_backtrace(ruby_backtrace)

      filters = opts[:filters] || []
      filtered_lines = ruby_lines.to_a.map do |line|
        filters.inject(line) do |line, proc|
          proc.call(line)
        end
      end.compact

      lines = filtered_lines.collect do |unparsed_line|
        Line.parse(unparsed_line)
      end

      instance = new(lines)
    end

    def initialize(lines)
      self.lines = lines
    end

    def inspect
      "<Backtrace: " + lines.collect { |line| line.inspect }.join(", ") + ">"
    end

    def ==(other)
      if other.respond_to?(:lines)
        lines == other.lines
      else
        false
      end
    end

    private

    attr_writer :lines

    def self.split_multiline_backtrace(backtrace)
      if backtrace.to_a.size == 1
        backtrace.to_a.first.split(/\n\s*/)
      else
        backtrace
      end
    end
  end
end
