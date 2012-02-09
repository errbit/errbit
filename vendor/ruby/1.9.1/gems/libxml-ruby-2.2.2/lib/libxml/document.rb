# encoding: UTF-8

module LibXML
  module XML
    class Document
      # call-seq:
      #    XML::Document.document(document) -> XML::Document
      #
      # Creates a new document based on the specified document.
      #
      # Parameters:
      #
      #  document - A preparsed document.
      def self.document(value)
        Parser.document(value).parse
      end

      # call-seq:
      #    XML::Document.file(path) -> XML::Document
      #    XML::Document.file(path, :encoding => XML::Encoding::UTF_8,
      #                             :options => XML::Parser::Options::NOENT) -> XML::Document
      #
      # Creates a new document from the specified file or uri.
      #
      # You may provide an optional hash table to control how the
      # parsing is performed.  Valid options are:
      #
      #  encoding - The document encoding, defaults to nil. Valid values
      #             are the encoding constants defined on XML::Encoding.
      #  options - Parser options.  Valid values are the constants defined on
      #            XML::Parser::Options.  Mutliple options can be combined
      #            by using Bitwise OR (|).
      def self.file(value, options = {})
        Parser.file(value, options).parse
      end

      # call-seq:
      #    XML::Document.io(io) -> XML::Document
      #    XML::Document.io(io, :encoding => XML::Encoding::UTF_8,
      #                         :options => XML::Parser::Options::NOENT
      #                         :base_uri="http://libxml.org") -> XML::Document
      #
      # Creates a new document from the specified io object.
      #
      # Parameters:
      #
      #  io - io object that contains the xml to parser
      #  base_uri - The base url for the parsed document.
      #  encoding - The document encoding, defaults to nil. Valid values
      #             are the encoding constants defined on XML::Encoding.
      #  options - Parser options.  Valid values are the constants defined on
      #            XML::Parser::Options.  Mutliple options can be combined
      #            by using Bitwise OR (|).
      def self.io(value, options = {})
        Parser.io(value, options).parse
      end

      # call-seq:
      #    XML::Document.string(string)
      #    XML::Document.string(string, :encoding => XML::Encoding::UTF_8,
      #                               :options => XML::Parser::Options::NOENT
      #                               :base_uri="http://libxml.org") -> XML::Document
      #
      # Creates a new document from the specified string.
      #
      # You may provide an optional hash table to control how the
      # parsing is performed.  Valid options are:
      #
      #  base_uri - The base url for the parsed document.
      #  encoding - The document encoding, defaults to nil. Valid values
      #             are the encoding constants defined on XML::Encoding.
      #  options - Parser options.  Valid values are the constants defined on
      #            XML::Parser::Options.  Mutliple options can be combined
      #            by using Bitwise OR (|).
      def self.string(value, options = {})
        Parser.string(value, options).parse
      end

      # Returns a new XML::XPathContext for the document.
      #
      # call-seq:
      #   document.context(namespaces=nil) -> XPath::Context
      #
      # Namespaces is an optional array of XML::NS objects
      def context(nslist = nil)
        context = XPath::Context.new(self)
        context.node = self.root
        context.register_namespaces_from_node(self.root)
        context.register_namespaces(nslist) if nslist
        context
      end

      # Return the nodes matching the specified xpath expression, 
      # optionally using the specified namespace.  For more 
      # information about working with namespaces, please refer
      # to the XML::XPath documentation.
      # 
      # Parameters:
      # * xpath - The xpath expression as a string
      # * namespaces - An optional list of namespaces (see XML::XPath for information).
      # * Returns - XML::XPath::Object
      #
      #  document.find('/foo', 'xlink:http://www.w3.org/1999/xlink')
      #
      # IMPORTANT - The returned XML::Node::Set must be freed before
      # its associated document.  In a running Ruby program this will
      # happen automatically via Ruby's mark and sweep garbage collector.
      # However, if the program exits, Ruby does not guarantee the order
      # in which objects are freed
      # (see http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-core/17700).
      # As a result, the associated document may be freed before the node
      # list, which will cause a segmentation fault.
      # To avoid this, use the following (non-ruby like) coding style:
      #
      #  nodes = doc.find('/header')
      #  nodes.each do |node|
      #    ... do stuff ...
      #  end
      # #  nodes = nil #  GC.start
      def find(xpath, nslist = nil)
        self.context(nslist).find(xpath)
      end
    
      # Return the first node matching the specified xpath expression.
      # For more information, please refer to the documentation
      # for XML::Document#find.
      def find_first(xpath, nslist = nil)
        find(xpath, nslist).first
      end
      
      # Returns this node's type name    
      def node_type_name
        case node_type
          when XML::Node::DOCUMENT_NODE
            'document_xml'
          when XML::Node::DOCB_DOCUMENT_NODE
            'document_docbook'
          when XML::Node::HTML_DOCUMENT_NODE
            'document_html'
          else
            raise(UnknownType, "Unknown node type: %n", node.node_type);
        end
      end
      # :enddoc:

      # Specifies if this is an document node
      def document?
        node_type == XML::Node::DOCUMENT_NODE
      end

      # Specifies if this is an docbook node
      def docbook_doc?
        node_type == XML::Node::DOCB_DOCUMENT_NODE
      end

      # Specifies if this is an html node
      def html_doc?
        node_type == XML::Node::HTML_DOCUMENT_NODE
      end

      def dump
        warn('Document#dump is deprecated.  Use Document#to_s instead.')
        self.to_s
      end

      def format_dump
        warn('Document#format_dump is deprecated.  Use Document#to_s instead.')
        self.to_s
      end

      def debug_dump
        warn('Document#debug_dump is deprecated.  Use Document#debug instead.')
        self.debug
      end

      def debug_dump_head
        warn('Document#debug_dump_head is deprecated.  Use Document#debug instead.')
        self.debug
      end

      def debug_format_dump
        warn('Document#debug_format_dump is deprecated.  Use Document#to_s instead.')
        self.to_s
      end

      def reader
        warn('Document#reader is deprecated.  Use XML::Reader.document(self) instead.')
        XML::Reader.document(self)
      end
    end
  end
end  
