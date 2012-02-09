# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:
      # Defines the behaviour for object fields.
      class Object
        include Serializable
      end
    end
  end
end
