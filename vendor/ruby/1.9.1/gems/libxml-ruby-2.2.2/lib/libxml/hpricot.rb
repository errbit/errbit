# encoding: UTF-8

## Provide hpricot API for libxml.  Provided by Michael Guterl,
## inspired by http://thebogles.com/blog/an-hpricot-style-interface-to-libxml
#
#class String
#  def to_libxml_doc
#    xp = XML::Parser.new
#    xp.string = self
#    xp.parse
#  end
#end
#
#module LibXML
#  module XML
#    class Document
#      alias :search :find
#    end
#
#    class Node
#      # find the child node with the given xpath
#      def at(xpath)
#        self.find_first(xpath)
#      end
#
#      # find the array of child nodes matching the given xpath
#      def search(xpath)
#        results = self.find(xpath).to_a
#        if block_given?
#          results.each do |result|
#            yield result
#          end
#        end
#        return results
#      end
#
#      def /(xpath)
#        search(xpath)
#      end
#
#      # return the inner contents of this node as a string
#      def inner_xml
#        child.to_s
#      end
#
#      # alias for inner_xml
#      def inner_html
#        inner_xml
#      end
#
#      # return this node and its contents as an xml string
#      def to_xml
#        self.to_s
#      end
#
#      # alias for path
#      def xpath
#        self.path
#      end
#
#      def find_with_default_ns(xpath_expr, namespace=nil)
#        find_base(xpath_expr, namespace || default_namespaces)
#      end
#
#      def find_first_with_default_ns(xpath_expr, namespace=nil)
#        find_first_base(xpath_expr, namespace || default_namespaces)
#      end
#
##      alias_method :find_base, :find unless method_defined?(:find_base)
##      alias_method :find, :find_with_default_ns
##      alias_method :find_first_base, :find_first unless method_defined?(:find_first_base)
##      alias_method :find_first, :find_first_with_default_ns
##      alias :child? :first?
##      alias :children? :first?
##      alias :child :first
#    end
#  end
#end