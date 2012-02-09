# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:

    # Defines the behaviour for defined fields in the document.
    #
    # For people who want to have custom field types in their
    # applications and want control over the serialization process
    # to and from the domain model and MongoDB you will need to include
    # this module in your custom type class. You will also need to define
    # either a #serialize and #deserialize instance method, where previously
    # these were a .set and .get class method respectively.
    #
    #   class MyCustomType
    #     include Mongoid::Fields::Serializable
    #
    #     def deserialize(object)
    #       # Do something to convert it from Mongo to my type.
    #     end
    #
    #     def serialize(object)
    #       # Do something to convert from my type to MongoDB friendly.
    #     end
    #   end
    module Serializable
      extend ActiveSupport::Concern

      # Set readers for the instance variables.
      attr_accessor :default, :label, :name, :options

      # When reading the field do we need to cast the value? This holds true when
      # times are stored or for big decimals which are stored as strings.
      #
      # @example Typecast on a read?
      #   field.cast_on_read?
      #
      # @return [ true, false ] If the field should be cast.
      #
      # @since 2.1.0
      def cast_on_read?
        return @cast_on_read if defined?(@cast_on_read)
        @cast_on_read =
          self.class.public_instance_methods(false).map do |m|
            m.to_sym
          end.include?(:deserialize)
      end

      # Get the constraint from the metadata once.
      #
      # @example Get the constraint.
      #   field.constraint
      #
      # @return [ Constraint ] The relation's contraint.
      #
      # @since 2.1.0
      def constraint
        @constraint ||= metadata.constraint
      end

      # Deserialize this field from the type stored in MongoDB to the type
      # defined on the model
      #
      # @example Deserialize the field.
      #   field.deserialize(object)
      #
      # @param [ Object ] object The object to cast.
      #
      # @return [ Object ] The converted object.
      #
      # @since 2.1.0
      def deserialize(object); object; end

      # Evaluate the default value and return it. Will handle the
      # serialization, proc calls, and duplication if necessary.
      #
      # @example Evaluate the default value.
      #   field.eval_default(document)
      #
      # @param [ Document ] doc The document the field belongs to.
      #
      # @return [ Object ] The serialized default value.
      #
      # @since 2.1.8
      def eval_default(doc)
        if default.respond_to?(:call)
          serialize(doc.instance_exec(&default))
        else
          serialize(default.duplicable? ? default.dup : default)
        end
      end

      # Get the metadata for the field if its a foreign key.
      #
      # @example Get the metadata.
      #   field.metadata
      #
      # @return [ Metadata ] The relation metadata.
      #
      # @since 2.2.0
      def metadata
        @metadata ||= options[:metadata]
      end

      # Is the field a BSON::ObjectId?
      #
      # @example Is the field a BSON::ObjectId?
      #   field.object_id_field?
      #
      # @return [ true, false ] If the field is a BSON::ObjectId.
      #
      # @since 2.2.0
      def object_id_field?
        @object_id_field ||= (type == BSON::ObjectId)
      end

      # Serialize the object from the type defined in the model to a MongoDB
      # compatible object to store.
      #
      # @example Serialize the field.
      #   field.serialize(object)
      #
      # @param [ Object ] object The object to cast.
      #
      # @return [ Object ] The converted object.
      #
      # @since 2.1.0
      def serialize(object); object; end

      # Get the type of this field - inferred from the class name.
      #
      # @example Get the type.
      #   field.type
      #
      # @return [ Class ] The name of the class.
      #
      # @since 2.1.0
      def type
        @type ||= options[:type] || Object
      end

      # Is this field included in versioned attributes?
      #
      # @example Is the field versioned?
      #   field.versioned?
      #
      # @return [ true, false ] If the field is included in versioning.
      #
      # @since 2.1.0
      def versioned?
        @versioned ||= (options[:versioned].nil? ? true : options[:versioned])
      end

      module ClassMethods #:nodoc:

        # Create the new field with a name and optional additional options.
        #
        # @example Create the new field.
        #   Field.new(:name, :type => String)
        #
        # @param [ Hash ] options The field options.
        #
        # @option options [ Class ] :type The class of the field.
        # @option options [ Object ] :default The default value for the field.
        # @option options [ String ] :label The field's label.
        #
        # @since 2.1.0
        def instantiate(name, options = {})
          allocate.tap do |field|
            field.name = name
            field.options = options
            field.default = options[:default]
            field.label = options[:label]
          end
        end
      end
    end
  end
end
