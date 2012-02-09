# encoding: UTF-8

module LibXML
  module XML
    class Node
      def property(name)
        warn('Node#properties is deprecated.  Use Node#[] instead.')
        self[name]
      end

      def properties
        warn('Node#properties is deprecated.  Use Node#attributes instead.')
        self.attributes
      end

      def properties?
        warn('Node#properties? is deprecated.  Use Node#attributes? instead.')
        self.attributes?
      end
    end

  end
end