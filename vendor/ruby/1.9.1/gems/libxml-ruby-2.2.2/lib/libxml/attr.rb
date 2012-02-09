# encoding: UTF-8

module LibXML
  module XML
    class Attr 
      include Enumerable

      # call-seq:
      #    attr.child? -> (true|false)
      #
      # Returns whether this attribute has child attributes.
      #
      def child?
        not self.children.nil?
      end

      # call-seq:
      #    attr.doc? -> (true|false)
      #
      # Determine whether this attribute is associated with an
      # XML::Document.
      def doc?
        not self.doc.nil?
      end

      # call-seq:
      #    attr.last? -> (true|false)
      #
      # Determine whether this is the last attribute.
      def last?
        self.last.nil?
      end

      # call-seq:
      #    attr.next? -> (true|false)
      #
      # Determine whether there is a next attribute.
      def next?
        not self.next.nil?
      end

      # call-seq:
      #    attr.ns? -> (true|false)
      #
      # Determine whether this attribute has an associated
      # namespace.
      def ns?
        not self.ns.nil?
      end

      # call-seq:
      #   attr.namespacess -> XML::Namespaces
      #
      # Returns this node's XML::Namespaces object,
      # which is used to access the namespaces
      # associated with this node.
      def namespaces
        @namespaces ||= XML::Namespaces.new(self)
      end
      
      #
      # call-seq:
      #    attr.parent? -> (true|false)
      #
      # Determine whether this attribute has a parent.
      def parent?
        not self.parent.nil?
      end

      # call-seq:
      #    attr.prev? -> (true|false)
      #
      # Determine whether there is a previous attribute.
      def prev?
        not self.prev.nil?
      end

      # Returns this node's type name
      def node_type_name
        if node_type == Node::ATTRIBUTE_NODE
          'attribute'
        else
          raise(UnknownType, "Unknown node type: %n", node.node_type);
        end
      end

      # Iterates nodes and attributes
      def siblings(node, &blk)
        if n = node
          loop do
            blk.call(n)
            break unless n = n.next
          end
        end
      end

      def each_sibling(&blk)
        siblings(self,&blk)
      end
  
      alias :each_attr :each_sibling
      alias :each :each_sibling
  
      def to_h
        inject({}) do |h,a|
          h[a.name] = a.value
          h
        end
      end

      def to_a
        inject([]) do |ary,a| 
          ary << [a.name, a.value]
          ary
        end
      end
  
      def to_s
        "#{name} = #{value}"
      end
    end
  end
end