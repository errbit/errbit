# encoding: UTF-8

module LibXML
  module XML
    class AttrDecl
      include Enumerable

      # call-seq:
      #   attr_decl.child -> nil
      #
      # Obtain this attribute declaration's child attribute(s).
      # It will always be nil.
      def child
        nil
      end

      # call-seq:
      #    attr_decl.child? -> (true|false)
      #
      # Returns whether this attribute declaration has child attributes.
      #
      def child?
        not self.children.nil?
      end

      # call-seq:
      #    attr_decl.doc? -> (true|false)
      #
      # Determine whether this attribute declaration is associated with an
      # XML::Document.
      def doc?
        not self.doc.nil?
      end

      # call-seq:
      #    attr_decl.next? -> (true|false)
      #
      # Determine whether there is a next attribute declaration.
      def next?
        not self.next.nil?
      end

      # call-seq:
      #    attr_decl.parent? -> (true|false)
      #
      # Determine whether this attribute declaration has a parent .
      def parent?
        not self.parent.nil?
      end

      # call-seq:
      #    attr_decl.prev? -> (true|false)
      #
      # Determine whether there is a previous attribute declaration.
      def prev?
        not self.prev.nil?
      end

      # call-seq:
      #    attr_decl.node_type_name -> 'attribute declaration'
      #
      # Returns this attribute declaration's node type name.
      def node_type_name
        if node_type == Node::ATTRIBUTE_DECL
          'attribute declaration'
        else
          raise(UnknownType, "Unknown node type: %n", node.node_type);
        end
      end

      # call-seq:
      #    attr_decl.to_s -> string
      #
      # Returns a string representation of this attribute declaration.
      def to_s
        "#{name} = #{value}"
      end
    end
  end
end
