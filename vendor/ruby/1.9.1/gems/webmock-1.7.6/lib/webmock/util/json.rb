# This is a copy of https://github.com/jnunemaker/crack/blob/master/lib/crack/json.rb
# with date parsing removed
module WebMock
  module Util
    class JSON
      def self.parse(json)
        YAML.load(unescape(convert_json_to_yaml(json)))
      rescue ArgumentError => e
        raise ParseError, "Invalid JSON string"
      end

      protected
      def self.unescape(str)
        str.gsub(/\\u([0-9a-f]{4})/) { [$1.hex].pack("U") }
      end

      # Ensure that ":" and "," are always followed by a space
      def self.convert_json_to_yaml(json) #:nodoc:
        scanner, quoting, marks, pos, times = StringScanner.new(json), false, [], nil, []
        while scanner.scan_until(/(\\['"]|['":,\\]|\\.)/)
          case char = scanner[1]
          when '"', "'"
            if !quoting
              quoting = char
              pos = scanner.pos
            elsif quoting == char
              quoting = false
            end
          when ":",","
              marks << scanner.pos - 1 unless quoting
          when "\\"
              scanner.skip(/\\/)
          end
        end

        if marks.empty?
          json.gsub(/\\\//, '/')
        else
          left_pos  = [-1].push(*marks)
          right_pos = marks << json.length
          output    = []
          left_pos.each_with_index do |left, i|
            output << json[left.succ..right_pos[i]]
          end
          output = output * " "

          times.each { |i| output[i-1] = ' ' }
          output.gsub!(/\\\//, '/')
          output
        end
      end
    end
  end
end
