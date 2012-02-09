class UserAgent
  class Version
    include ::Comparable

    def self.new(obj)
      case obj
      when Version
        obj
      when String
        super
      else
        raise ArgumentError, "invalid value for Version: #{obj.inspect}"
      end
    end

    def initialize(str)
      @str = str

      if str =~ /^\d+$/ || str =~ /^\d+\./
        @sequences  = str.scan(/\d+|[A-Za-z][0-9A-Za-z-]*$/).map { |s| s =~ /^\d+$/ ? s.to_i : s }
        @comparable = true
      else
        @sequences  = [str]
        @comparable = false
      end
    end

    def to_a
      @sequences.dup
    end

    def to_str
      @str.dup
    end

    def eql?(other)
      other.is_a?(self.class) && to_s == other.to_s
    end

    def ==(other)
      case other
      when Version
        eql?(other)
      when String
        eql?(self.class.new(other))
      else
        false
      end
    end

    def <=>(other)
      case other
      when Version
        if @comparable
          to_a.zip(other.to_a).each do |a, b|
            if b.nil?
              return -1
            elsif a.nil?
              return 1
            elsif a.is_a?(String) && b.is_a?(Integer)
              return -1
            elsif a.is_a?(Integer) && b.is_a?(String)
              return 1
            elsif a == b
              next
            else
              return a <=> b
            end
          end
          0
        else
          to_s == other.to_s ? 0 : nil
        end
      when String
        self <=> self.class.new(other)
      else
        raise ArgumentError, "comparison of Version with #{other.inspect} failed"
      end
    end

    def to_s
      to_str
    end

    def inspect
      "#<#{self.class} #{to_s}>"
    end
  end
end
