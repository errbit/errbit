# encoding: utf-8
module Mongoid #:nodoc:
  module Relations #:nodoc:

    # This is the superclass for all many to one and many to many relation
    # proxies.
    class Many < Proxy

      delegate :avg, :max, :min, :sum, :to => :criteria
      delegate :length, :size, :to => :target

      # Is the relation empty?
      #
      # @example Is the relation empty??
      #   person.addresses.blank?
      #
      # @return [ true, false ] If the relation is empty or not.
      #
      # @since 2.1.0
      def blank?
        size == 0
      end

      # Determine if any documents in this relation exist in the database.
      #
      # @example Are there persisted documents?
      #   person.posts.exists?
      #
      # @return [ true, false ] True is persisted documents exist, false if not.
      def exists?
        count > 0
      end

      # Find the first document given the conditions, or creates a new document
      # with the conditions that were supplied.
      #
      # @example Find or create.
      #   person.posts.find_or_create_by(:title => "Testing")
      #
      # @param [ Hash ] attrs The attributes to search or create with.
      #
      # @return [ Document ] An existing document or newly created one.
      def find_or_create_by(attrs = {}, &block)
        find_or(:create, attrs, &block)
      end

      # Find the first +Document+ given the conditions, or instantiates a new document
      # with the conditions that were supplied
      #
      # @example Find or initialize.
      #   person.posts.find_or_initialize_by(:title => "Test")
      #
      # @param [ Hash ] attrs The attributes to search or initialize with.
      #
      # @return [ Document ] An existing document or newly instantiated one.
      def find_or_initialize_by(attrs = {}, &block)
        find_or(:build, attrs, &block)
      end

      # This proxy can never be nil.
      #
      # @example Is the proxy nil?
      #   relation.nil?
      #
      # @return [ false ] Always false.
      #
      # @since 2.0.0
      def nil?
        false
      end

      # Since method_missing is overridden we should override this as well.
      #
      # @example Does the proxy respond to the method?
      #   relation.respond_to?(:name)
      #
      # @param [ Symbol ] name The method name.
      #
      # @return [ true, false ] If the proxy responds to the method.
      #
      # @since 2.0.0
      def respond_to?(name, include_private = false)
        [].respond_to?(name, include_private) ||
          klass.respond_to?(name, include_private) || super
      end

      # This is public access to the relation's criteria.
      #
      # @example Get the scoped relation.
      #   relation.scoped
      #
      # @return [ Criteria ] The scoped criteria.
      #
      # @since 2.1.0
      def scoped
        criteria
      end

      # Gets the document as a serializable hash, used by ActiveModel's JSON and
      # XML serializers. This override is just to be able to pass the :include
      # and :except options to get associations in the hash.
      #
      # @example Get the serializable hash.
      #   relation.serializable_hash
      #
      # @param [ Hash ] options The options to pass.
      #
      # @option options [ Symbol ] :include What relations to include
      # @option options [ Symbol ] :only Limit the fields to only these.
      # @option options [ Symbol ] :except Dont include these fields.
      #
      # @return [ Hash ] The documents, ready to be serialized.
      #
      # @since 2.0.0.rc.6
      def serializable_hash(options = {})
        target.map { |document| document.serializable_hash(options) }
      end

      private

      # Find the first object given the supplied attributes or create/initialize it.
      #
      # @example Find or create|initialize.
      #   person.addresses.find_or(:create, :street => "Bond")
      #
      # @param [ Symbol ] method The method name, create or new.
      # @param [ Hash ] attrs The attributes to build with.
      #
      # @return [ Document ] A matching document or a new/created one.
      def find_or(method, attrs = {}, &block)
        find(:first, :conditions => attrs) || send(method, attrs, &block)
      end
    end
  end
end
