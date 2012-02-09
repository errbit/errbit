# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Object #:nodoc:

      # This module is for defining base substitutable behaviour.
      module Substitutable #:nodoc:

        def substitutable
          self
        end
      end
    end
  end
end
