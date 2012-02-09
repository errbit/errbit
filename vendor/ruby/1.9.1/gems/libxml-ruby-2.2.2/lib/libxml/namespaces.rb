# encoding: UTF-8

module LibXML
  module XML
    class Namespaces
      # call-seq:
      #   namespace.default -> XML::Namespace
      #
      # Returns the default namespace for this node or nil.
      #
      # Usage:
      #   doc = XML::Document.string('<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"/>')
      #   ns = doc.root.namespaces.default_namespace
      #   assert_equal(ns.href, 'http://schemas.xmlsoap.org/soap/envelope/')
      def default
        find_by_prefix(nil)
      end

      # call-seq:
      #   namespace.default_prefix = "string"
      #
      # Assigns a name (prefix) to the default namespace.
      # This makes it much easier to perform XML::XPath
      # searches.
      #
      # Usage:
      #   doc = XML::Document.string('<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"/>')
      #   doc.root.namespaces.default_prefix = 'soap'
      #   node = doc.root.find_first('soap:Envelope')
      def default_prefix=(prefix)
        # Find default prefix
        ns = find_by_prefix(nil)
        raise(ArgumentError, "No default namespace was found") unless ns
        Namespace.new(self.node, prefix, ns.href)
      end
    end
  end
end