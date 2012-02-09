# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:
      # Defines the behaviour for hash fields.
      class Hash
        include Serializable
      end
    end
  end
end
