require 'crack/xml'

module Fogbugz
  module Adapter
    module XML
      class Cracker
        def self.parse(xml)
          Crack::XML.parse(xml)["response"]
        end
      end
    end
  end
end
