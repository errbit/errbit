# encoding: UTF-8

module LibXML
  module XML
    class Namespace
      include Comparable
      include Enumerable

      # call-seq:
      #   namespace1 <=> namespace2
      #
      # Compares two namespace objects.  Namespace objects are
      # considered equal if their prefixes and hrefs are the same.
      def <=>(other)
        if self.prefix.nil? and other.prefix.nil?
          self.href <=> other.href
        elsif self.prefix.nil?
          -1
        elsif other.prefix.nil?
          1
        else
          self.prefix <=> other.prefix
        end
      end

      # call-seq:
      #   namespace.each {|ns| .. }
      #
      # libxml stores namespaces in memory as a linked list.
      # Use the each method to iterate over the list.  Note
      # the first namespace in the loop is the current namespace.
      #
      # Usage:
      #   namespace.each do |ns|
      #     ..
      #   end
      def each
        ns = self

        while ns
          yield ns
          ns = ns.next
        end
      end

      # call-seq:
      #   namespace.to_s -> "string"
      #
      # Returns the string represenation of a namespace.
      #
      # Usage:
      #   namespace.to_s
      def to_s
        if self.prefix
          "#{self.prefix}:#{self.href}"
        else
          self.href
        end
      end
    end
  end
end