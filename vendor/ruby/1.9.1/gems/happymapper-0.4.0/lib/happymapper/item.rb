module HappyMapper
  class Item
    attr_accessor :name, :type, :tag, :options, :namespace
    
    Types = [String, Float, Time, Date, DateTime, Integer, Boolean]
    
    # options:
    #   :deep   =>  Boolean False to only parse element's children, True to include
    #               grandchildren and all others down the chain (// in expath)
    #   :namespace => String Element's namespace if it's not the global or inherited
    #                  default
    #   :parser =>  Symbol Class method to use for type coercion.
    #   :raw    =>  Boolean Use raw node value (inc. tags) when parsing.
    #   :single =>  Boolean False if object should be collection, True for single object
    #   :tag    =>  String Element name if it doesn't match the specified name.
    def initialize(name, type, o={})
      self.name = name.to_s
      self.type = type
      self.tag = o.delete(:tag) || name.to_s
      self.options = o
      
      @xml_type = self.class.to_s.split('::').last.downcase
    end
    
    def constant
      @constant ||= constantize(type)
    end
        
    def from_xml_node(node, namespace)
      if primitive?
        find(node, namespace) do |n|
          if n.respond_to?(:content)
            typecast(n.content)
          else
            typecast(n.to_s)
          end
        end
      else
        if options[:parser]
          find(node, namespace) do |n|
            if n.respond_to?(:content) && !options[:raw]
              value = n.content
            else
              value = n.to_s
            end

            begin
              constant.send(options[:parser].to_sym, value)
            rescue
              nil
            end
          end
        else
          constant.parse(node, options)
        end
      end
    end
    
    def xpath(namespace = self.namespace)
      xpath  = ''
      xpath += './/' if options[:deep]
      xpath += "#{DEFAULT_NS}:" if namespace
      xpath += tag
      # puts "xpath: #{xpath}"
      xpath
    end
    
    def primitive?
      Types.include?(constant)
    end
    
    def element?
      @xml_type == 'element'
    end
    
    def attribute?
      !element?
    end
    
    def method_name
      @method_name ||= name.tr('-', '_')
    end
    
    def typecast(value)
      return value if value.kind_of?(constant) || value.nil?
      begin        
        if    constant == String    then value.to_s
        elsif constant == Float     then value.to_f
        elsif constant == Time      then Time.parse(value.to_s)
        elsif constant == Date      then Date.parse(value.to_s)
        elsif constant == DateTime  then DateTime.parse(value.to_s)
        elsif constant == Boolean   then ['true', 't', '1'].include?(value.to_s.downcase)
        elsif constant == Integer
          # ganked from datamapper
          value_to_i = value.to_i
          if value_to_i == 0 && value != '0'
            value_to_s = value.to_s
            begin
              Integer(value_to_s =~ /^(\d+)/ ? $1 : value_to_s)
            rescue ArgumentError
              nil
            end
          else
            value_to_i
          end
        else
          value
        end
      rescue
        value
      end
    end
    
    private
      def constantize(type)
        if type.is_a?(String)
          names = type.split('::')
          constant = Object
          names.each do |name|
            constant =  constant.const_defined?(name) ? 
                          constant.const_get(name) : 
                          constant.const_missing(name)
          end
          constant
        else
          type
        end
      end
      
      def find(node, namespace, &block)
        if options[:namespace] == false
          namespace = nil
        elsif options[:namespace]
          # from an element definition
          namespace = "#{DEFAULT_NS}:#{options[:namespace]}"
        elsif self.namespace
          # this node has a custom namespace (that is present in the doc)
          namespace = "#{DEFAULT_NS}:#{self.namespace}"
        end
        
        if element?
          if(options[:single].nil? || options[:single])
            result = node.find_first(xpath(namespace), namespace)
          else
            result = node.find(xpath(namespace))
          end
          # puts "vfxn: #{xpath} #{result.inspect}"
          if result
            if(options[:single].nil? || options[:single])
              value = yield(result)
            else
              value = []

              result.each do |res|
                value << yield(res)
              end
            end
            if options[:attributes].is_a?(Hash)
              result.attributes.each do |xml_attribute|
                if attribute_options = options[:attributes][xml_attribute.name.to_sym]
                  attribute_value = Attribute.new(xml_attribute.name.to_sym, *attribute_options).from_xml_node(result, namespace)
                  result.instance_eval <<-EOV
                    def value.#{xml_attribute.name}
                      #{attribute_value.inspect}
                    end
                  EOV
                end
              end
            end
            value
          else
            nil
          end
        else
          yield(node[tag])
        end
      end
  end
end