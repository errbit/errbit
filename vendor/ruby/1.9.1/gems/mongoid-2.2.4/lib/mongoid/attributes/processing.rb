# encoding: utf-8
module Mongoid #:nodoc:
  module Attributes #:nodoc:

    # This module contains the behavior for processing attributes.
    module Processing

      # Process the provided attributes casting them to their proper values if a
      # field exists for them on the document. This will be limited to only the
      # attributes provided in the suppied +Hash+ so that no extra nil values get
      # put into the document's attributes.
      #
      # @example Process the attributes.
      #   person.process(:title => "sir", :age => 40)
      #
      # @param [ Hash ] attrs The attributes to set.
      # @param [ Boolean ] guard_protected_attributes False to skip mass assignment protection.
      #
      # @since 2.0.0.rc.7
      def process(attrs = nil, guard_protected_attributes = true)
        attrs ||= {}
        attrs = sanitize_for_mass_assignment(attrs) if guard_protected_attributes
        attrs.each_pair do |key, value|
          next if pending_attribute?(key, value)
          process_attribute(key, value)
        end
        yield self if block_given?
        process_pending
      end

      protected

      # If the key provided is the name of a relation or a nested attribute, we
      # need to wait until all other attributes are set before processing
      # these.
      #
      # @example Is the attribute pending?
      #   document.pending_attribute?(:name, "Durran")
      #
      # @param [ Synbol ] key The name of the attribute.
      # @param [ Object ] value The value of the attribute.
      #
      # @return [ true, false ] True if pending, false if not.
      #
      # @since 2.0.0.rc.7
      def pending_attribute?(key, value)
        name = key.to_s
        if relations.has_key?(name)
          pending_relations[name] = value
          return true
        end
        if nested_attributes.include?("#{name}=")
          pending_nested[name] = value
          return true
        end
        return false
      end

      # Get all the pending relations that need to be set.
      #
      # @example Get the pending relations.
      #   document.pending_relations
      #
      # @return [ Hash ] The pending relations in key/value pairs.
      #
      # @since 2.0.0.rc.7
      def pending_relations
        @pending_relations ||= {}
      end

      # Get all the pending nested attributes that need to be set.
      #
      # @example Get the pending nested attributes.
      #   document.pending_nested
      #
      # @return [ Hash ] The pending nested attributes in key/value pairs.
      #
      # @since 2.0.0.rc.7
      def pending_nested
        @pending_nested ||= {}
      end

      # If the attribute is dynamic, add a field for it with a type of object
      # and then either way set the value.
      #
      # @example Process the attribute.
      #   document.process_attribute(name, value)
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Object ] value The value of the field.
      #
      # @since 2.0.0.rc.7
      def process_attribute(name, value)
        if Mongoid.allow_dynamic_fields && !respond_to?("#{name}=")
          write_attribute(name, value)
        else
          send("#{name}=", value)
        end
      end

      # Process all the pending nested attributes that needed to wait until
      # ids were set to fire off.
      #
      # @example Process the nested attributes.
      #   document.process_nested
      #
      # @since 2.0.0.rc.7
      def process_nested
        pending_nested.each_pair do |name, value|
          send("#{name}=", value)
        end
      end

      # Process all the pending items, then clear them out.
      #
      # @example Process the pending items.
      #   document.process_pending
      #
      # @since 2.0.0.rc.7
      def process_pending
        process_nested and process_relations
        pending_nested.clear and pending_relations.clear
      end

      # Process all the pending relations that needed to wait until ids were set
      # to fire off.
      #
      # @example Process the relations.
      #   document.process_relations
      #
      # @since 2.0.0.rc.7
      def process_relations
        pending_relations.each_pair do |name, value|
          metadata = relations[name]
          if value.is_a?(Hash)
            metadata.nested_builder(value, {}).build(self)
          else
            send("#{name}=", value)
          end
        end
      end
    end
  end
end

