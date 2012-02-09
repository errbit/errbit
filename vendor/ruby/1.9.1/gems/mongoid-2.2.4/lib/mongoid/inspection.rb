# encoding: utf-8
module Mongoid #:nodoc

  # Contains the bahviour around inspecting documents via
  # <tt>Object#inspect</tt>.
  module Inspection

    # Returns the class name plus its attributes. If using dynamic fields will
    # include those as well.
    #
    # @example Inspect the document.
    #   person.inspect
    #
    # @return [ String ] A nice pretty string to look at.
    def inspect
      inspection = []
      inspection.concat(inspect_fields).concat(inspect_dynamic_fields)
      "#<#{self.class.name} _id: #{id}, #{inspection * ', '}>"
    end

    private

    # Get an array of inspected fields for the document.
    #
    # @example Inspect the defined fields.
    #   document.inspect_fields
    #
    # @return [ String ] An array of pretty printed field values.
    def inspect_fields
      fields.map do |name, field|
        unless name == "_id"
          "#{name}: #{@attributes[name].inspect}"
        end
      end.compact
    end

    # Get an array of inspected dynamic fields for the document.
    #
    # @example Inspect the dynamic fields.
    #   document.inspect_dynamic_fields
    #
    # @return [ String ] An array of pretty printed dynamic field values.
    def inspect_dynamic_fields
      if Mongoid.allow_dynamic_fields
        keys = @attributes.keys - fields.keys - relations.keys - ["_id", "_type"]
        return keys.map do |name|
          "#{name}: #{@attributes[name].inspect}"
        end
      else
        []
      end
    end
  end
end
