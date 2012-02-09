# encoding: UTF-8

module LibXML
  module XML
    module XPath
      class Object
        alias :size :length

        def set
          warn("XPath::Object#set is deprecated.  Simply use the XPath::Object API instead")
          self
        end
      end
    end
  end
end