# encoding: UTF-8

module LibXML
  module XML
    class NS < Namespace # :nodoc: 
      def initialize(node, prefix, href)
        warn('The XML::NS class is deprecated.  Use XML::Namespace instead.')
        super(node, href, prefix)
      end

      def href?
        warn('XML::NS#href? is deprecated.  Use !XML::NS#href.nil? instead.')
        not self.href.nil?
      end

      def prefix?
        warn('XML::NS#prefix? is deprecated.  Use !XML::NS#prefix?.nil? instead.')
        not self.previx.nil?
      end
    end
  end
end