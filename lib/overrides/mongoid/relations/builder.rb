# ruby-fogbugz requires crack. crack adds the attributes method to strings,
# thus breaking the relations of Mongoid.
# Tests reside in a separate fork of mongoid:
# https://github.com/mhs/mongoid/commit/e5b2b1346c73a2935c606317314b6ded07260429#diff-1
module Mongoid
  module Relations
    class Builder
      def query?
        return true unless object.respond_to?(:to_a)
        obj = object.to_a.first
        !obj.is_a?(Mongoid::Document) && !obj.nil?
      end
    end
  end
end
