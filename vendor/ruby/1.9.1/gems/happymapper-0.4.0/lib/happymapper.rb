require 'rubygems'
require 'date'
require 'time'
require 'xml'

class Boolean; end

module HappyMapper

  DEFAULT_NS = "happymapper"

  def self.included(base)
    base.instance_variable_set("@attributes", {})
    base.instance_variable_set("@elements", {})
    base.instance_variable_set("@registered_namespaces", {})
    
    base.extend ClassMethods
  end

  module ClassMethods
    def attribute(name, type, options={})
      attribute = Attribute.new(name, type, options)
      @attributes[to_s] ||= []
      @attributes[to_s] << attribute
      attr_accessor attribute.method_name.intern
    end

    def attributes
      @attributes[to_s] || []
    end

    def element(name, type, options={})
      element = Element.new(name, type, options)
      @elements[to_s] ||= []
      @elements[to_s] << element
      attr_accessor element.method_name.intern
    end

    def content(name)
      @content = name
      attr_accessor name
    end

    def after_parse_callbacks
      @after_parse_callbacks ||= []
    end

    def after_parse(&block)
      after_parse_callbacks.push(block)
    end

    def elements
      @elements[to_s] || []
    end

    def has_one(name, type, options={})
      element name, type, {:single => true}.merge(options)
    end

    def has_many(name, type, options={})
      element name, type, {:single => false}.merge(options)
    end

    # Specify a namespace if a node and all its children are all namespaced
    # elements. This is simpler than passing the :namespace option to each
    # defined element.
    def namespace(namespace = nil)
      @namespace = namespace if namespace
      @namespace
    end
    
    def register_namespace(namespace, ns)
      @registered_namespaces.merge!(namespace => ns)
    end

    def tag(new_tag_name)
      @tag_name = new_tag_name.to_s
    end

    def tag_name
      @tag_name ||= to_s.split('::')[-1].downcase
    end

    def parse(xml, options = {})
      if xml.is_a?(XML::Node)
        node = xml
      else
        if xml.is_a?(XML::Document)
          node = xml.root
        else
          node = XML::Parser.string(xml).parse.root
        end

        root = node.name == tag_name
      end

      namespace = @namespace || (node.namespaces && node.namespaces.default)
      namespace = "#{DEFAULT_NS}:#{namespace}" if namespace

      xpath = root ? '/' : './/'
      xpath += "#{DEFAULT_NS}:" if namespace
      xpath += tag_name

      nodes = node.find(xpath, Array(namespace))
      collection = nodes.collect do |n|
        obj = new

        attributes.each do |attr|
          obj.send("#{attr.method_name}=",
          attr.from_xml_node(n, namespace))
        end

        elements.each do |elem|
          obj.send("#{elem.method_name}=",
          elem.from_xml_node(n, namespace))
        end

        obj.send("#{@content}=", n.content) if @content

        obj.class.after_parse_callbacks.each { |callback| callback.call(obj) }

        obj
      end

      # per http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000354
      nodes = nil

      if options[:single] || root
        collection.first
      else
        collection
      end
    end

  end

  #
  # Create an xml representation of the specified class based on defined
  # HappyMapper elements and attributes. The method is defined in a way
  # that it can be called recursively by classes that are also HappyMapper
  # classes, allowg for the composition of classes.
  #
  def to_xml(parent_node = nil, default_namespace = nil)

    #
    # Create a tag that uses the tag name of the class that has no contents
    # but has the specified namespace or uses the default namespace
    #
    current_node = XML::Node.new(self.class.tag_name)


    if parent_node
      #
      # if #to_xml has been called with a parent_node that means this method
      # is being called recursively (or a special case) and we want to return
      # the parent_node with the new node as a child
      #
      parent_node << current_node
    else
      #
      # If #to_xml has been called without a Node (and namespace) that
      # means we want to return an xml document
      #
      write_out_to_xml = true
    end
    
    #
    # Add all the registered namespaces to the current node and the current node's
    # root element. Without adding it to the root element it is not possible to
    # parse or use xpath to find elements.
    #
    if self.class.instance_variable_get('@registered_namespaces')
      
      # Given a node, continue moving up to parents until there are no more parents
      find_root_node = lambda {|node| while node.parent? ; node = node.parent ; end ; node }
      root_node = find_root_node.call(current_node)
      
      # Add the registered namespace to the found root node only if it does not already have one defined
      self.class.instance_variable_get('@registered_namespaces').each_pair do |prefix,href|
        XML::Namespace.new(current_node,prefix,href)
        XML::Namespace.new(root_node,prefix,href) unless root_node.namespaces.find_by_prefix(prefix)
      end
    end

    #
    # Determine the tag namespace if one has been specified. This value takes
    # precendence over one that is handed down to composed sub-classes.
    #
    tag_namespace = current_node.namespaces.find_by_prefix(self.class.namespace) || default_namespace
    
    # Set the namespace of the current node to the specified namespace
    current_node.namespaces.namespace = tag_namespace if tag_namespace

    #
    # Add all the attribute tags to the current node with their namespace, if one
    # is defined, or the namespace handed down to the node.
    #
    self.class.attributes.each do |attribute|
      attribute_namespace = current_node.namespaces.find_by_prefix(attribute.options[:namespace]) || default_namespace
      
      value = send(attribute.method_name)

      #
      # If the attribute has a :on_save attribute defined that is a proc or
      # a defined method, then call those with the current value.
      #
      if on_save_operation = attribute.options[:on_save]
        if on_save_operation.is_a?(Proc)
          value = on_save_operation.call(value)
        elsif respond_to?(on_save_operation)
          value = send(on_save_operation,value)
        end
      end
      
      current_node[ "#{attribute_namespace ? "#{attribute_namespace.prefix}:" : ""}#{attribute.tag}" ] = value
    end

    #
    # All all the elements defined (e.g. has_one, has_many, element) ...
    #
    self.class.elements.each do |element|

      tag = element.tag || element.name
      
      element_namespace = current_node.namespaces.find_by_prefix(element.options[:namespace]) || tag_namespace
      
      value = send(element.name)

      #
      # If the element defines an :on_save lambda/proc then we will call that
      # operation on the specified value. This allows for operations to be 
      # performed to convert the value to a specific value to be saved to the xml.
      #
      if on_save_operation = element.options[:on_save]
        if on_save_operation.is_a?(Proc)
          value = on_save_operation.call(value)
        elsif respond_to?(on_save_operation)
          value = send(on_save_operation,value)
        end
      end

      #
      # Normally a nil value would be ignored, however if specified then
      # an empty element will be written to the xml
      #
      if value.nil? && element.options[:state_when_nil]
        current_node << XML::Node.new(tag,nil,element_namespace)
      end

      #
      # To allow for us to treat both groups of items and singular items
      # equally we wrap the value and treat it as an array.
      #
      if value.nil?
        values = []
      elsif value.respond_to?(:to_ary) && !element.options[:single]
        values = value.to_ary
      else
        values = [value]
      end


      values.each do |item|

        if item.is_a?(HappyMapper)

          #
          # Other HappyMapper items that are convertable should not be called
          # with the current node and the namespace defined for the element.
          #
          item.to_xml(current_node,element_namespace)

        elsif item

          #
          # When a value exists we should append the value for the tag
          #
          current_node << XML::Node.new(tag,item.to_s,element_namespace)

        else
          
          #
          # Normally a nil value would be ignored, however if specified then
          # an empty element will be written to the xml
          #
          current_node << XML.Node.new(tag,nil,element_namespace) if element.options[:state_when_nil]

        end

      end

    end


    #
    # Generate xml from a document if no node was passed as a parameter. Otherwise
    # this method is being called recursively (or special case) and we should
    # return the node with this node attached as a child.
    #
    if write_out_to_xml
      document = XML::Document.new
      document.root = current_node
      document.to_s
    else
      parent_node
    end

  end


end

require File.dirname(__FILE__) + '/happymapper/item'
require File.dirname(__FILE__) + '/happymapper/attribute'
require File.dirname(__FILE__) + '/happymapper/element'
