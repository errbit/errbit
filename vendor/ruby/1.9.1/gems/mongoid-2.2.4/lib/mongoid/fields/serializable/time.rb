# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:
      # Defines the behaviour for date fields.
      class Time
        include Serializable
        include Timekeeping
      end
    end
  end
end
