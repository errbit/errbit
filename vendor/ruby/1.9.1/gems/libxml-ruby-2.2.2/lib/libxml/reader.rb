# encoding: UTF-8

module LibXML
  module XML
    class Reader
      def reset_error_handler
        warn('reset_error_handler is deprecated.  Use Error.reset_handler instead')
        Error.reset_handler
      end

      def set_error_handler(&block)
        warn('set_error_handler is deprecated.  Use Error.set_handler instead')
        Error.set_handler(&block)
      end

      # :enddoc:

      def self.walker(doc)
        warn("XML::Reader.walker is deprecated.  Use XML::Reader.document instead")
        self.document(doc)
      end

      def self.data(string, options = nil)
        warn("XML::Reader.data is deprecated.  Use XML::Reader.string instead")
        self.string(string, options)
      end
    end
  end
end