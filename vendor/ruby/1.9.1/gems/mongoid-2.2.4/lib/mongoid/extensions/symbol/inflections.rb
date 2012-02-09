# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Symbol #:nodoc:

      # This module contains convenience methods for symbol inflection and
      # conversion.
      module Inflections

        REVERSALS = {
          :asc => :desc,
          :ascending => :descending,
          :desc => :asc,
          :descending => :ascending
        }

        # Get the inverted sorting option.
        #
        # @example Get the inverted option.
        #   :asc.invert
        #
        # @return [ String ] The string inverted.
        def invert
          REVERSALS[self]
        end

        # Define all the necessary methods on symbol to support Mongoid's
        # complex criterion.
        #
        # @example A greater than criterion.
        #   :field.gt => 5
        #
        # @return [ Criterion::Complex ] The criterion.
        #
        # @since 1.0.0
        [
          "all",
          "asc",
          "ascending",
          "desc",
          "descending",
          "exists",
          "gt",
          "gte",
          "in",
          "lt",
          "lte",
          "mod",
          "ne",
          "near",
          "nin",
          "size",
          "within",
          ["matches","elemMatch"] ].each do |oper|
          m, oper = oper
          oper = m unless oper
          class_eval <<-OPERATORS
            def #{m}
              Criterion::Complex.new(:key => self, :operator => "#{oper}")
            end
          OPERATORS
        end
      end
    end
  end
end
