class HTMLEntities
  class Decoder #:nodoc:
    def initialize(flavor)
      @flavor = flavor
      @map = HTMLEntities::MAPPINGS[@flavor]
      @entity_regexp = entity_regexp
    end

    def decode(source)
      prepare(source).gsub(@entity_regexp) {
        if $1 && codepoint = @map[$1]
          [codepoint].pack('U')
        elsif $2
          [$2.to_i(10)].pack('U')
        elsif $3
          [$3.to_i(16)].pack('U')
        else
          $&
        end
      }
    end

  private
    if "1.9".respond_to?(:encoding)
      def prepare(string) #:nodoc:
        string.to_s.encode(Encoding::UTF_8)
      end
    else
      def prepare(string) #:nodoc:
        string.to_s
      end
    end

    def entity_regexp
      key_lengths = @map.keys.map{ |k| k.length }
      entity_name_pattern =
        if @flavor == 'expanded'
          '(?:b\.)?[a-z][a-z0-9]'
        else
          '[a-z][a-z0-9]'
        end
      /&(?:(#{entity_name_pattern}{#{key_lengths.min - 1},#{key_lengths.max - 1}})|#([0-9]{1,7})|#x([0-9a-f]{1,6}));/i
    end
  end
end
