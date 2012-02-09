# encoding: utf-8
module Mongoid #:nodoc:
  module Validations #:nodoc:

    # Validates whether or not a field is unique against the documents in the
    # database.
    #
    # @example Define the uniqueness validator.
    #
    #   class Person
    #     include Mongoid::Document
    #     field :title
    #
    #     validates_uniqueness_of :title
    #   end
    class UniquenessValidator < ActiveModel::EachValidator

      # Unfortunately, we have to tie Uniqueness validators to a class.
      def setup(klass)
        @klass = klass
      end

      # Validate the document for uniqueness violations.
      #
      # @example Validate the document.
      #   validate_each(person, :title, "Sir")
      #
      # @param [ Document ] document The document to validate.
      # @param [ Symbol ] attribute The field to validate on.
      # @param [ Object ] value The value of the field.
      #
      # @todo Durran: This method needs refactoring.
      def validate_each(document, attribute, value)
        if document.embedded?
          return if document._parent.nil?
          criteria = document._parent.send(document.metadata.name)
          # If the parent document embeds_one, no need to validate uniqueness
          return if criteria.is_a?(Mongoid::Document)
          criteria = criteria.where(attribute => unique_search_value(value), :_id => {'$ne' => document._id})
        else
          criteria = @klass.where(attribute => unique_search_value(value))
          unless document.new_record?
            criteria = criteria.where(:_id => {'$ne' => document._id})
          end
        end

        Array.wrap(options[:scope]).each do |item|
          criteria = criteria.where(item => document.attributes[item.to_s])
        end
        if criteria.exists?
          document.errors.add(
            attribute,
            :taken,
            options.except(:case_sensitive, :scope).merge(:value => value)
          )
        end
      end

      protected

      # Determine if the primary key has changed on the document.
      #
      # @example Has the key changed?
      #   key_changed?(document)
      #
      # @param [ Document ] document The document to check.
      #
      # @return [ true, false ] True if changed, false if not.
      def key_changed?(document)
        (document.primary_key || {}).each do |key|
          return true if document.send("#{key}_changed?")
        end; false
      end

      # ensure :case_sensitive is true by default
      def unique_search_value(value)
        if options[:case_sensitive] == false
          value ? Regexp.new("^#{Regexp.escape(value.to_s)}$", Regexp::IGNORECASE) : nil
        else
          value
        end
      end
    end
  end
end
