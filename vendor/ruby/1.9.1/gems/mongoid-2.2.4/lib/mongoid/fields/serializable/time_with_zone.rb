# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:
      # Defines the behaviour for time with zone fields.
      class TimeWithZone
        include Serializable
        include Timekeeping
      end
    end
  end
end
