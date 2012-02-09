# encoding: UTF-8

module LibXML
  module XML
    class Attributes
      def to_h
        inject({}) do |hash, attr|
          hash[attr.name] = attr.value
          hash
        end
      end
    end
  end
end