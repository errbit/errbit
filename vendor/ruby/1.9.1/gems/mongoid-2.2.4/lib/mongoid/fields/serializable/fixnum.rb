# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:
      # Defines the behaviour for fixnum fields.
      class Fixnum < Integer
      end
    end
  end
end
