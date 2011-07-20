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
