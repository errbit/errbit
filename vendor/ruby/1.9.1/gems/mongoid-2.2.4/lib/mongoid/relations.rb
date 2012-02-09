# encoding: utf-8
require "mongoid/relations/accessors"
require "mongoid/relations/auto_save"
require "mongoid/relations/cascading"
require "mongoid/relations/constraint"
require "mongoid/relations/cyclic"
require "mongoid/relations/proxy"
require "mongoid/relations/bindings"
require "mongoid/relations/builders"
require "mongoid/relations/many"
require "mongoid/relations/one"
require "mongoid/relations/options"
require "mongoid/relations/polymorphic"
require "mongoid/relations/targets/enumerable"
require "mongoid/relations/embedded/atomic"
require "mongoid/relations/embedded/in"
require "mongoid/relations/embedded/many"
require "mongoid/relations/embedded/one"
require "mongoid/relations/referenced/batch"
require "mongoid/relations/referenced/in"
require "mongoid/relations/referenced/many"
require "mongoid/relations/referenced/many_to_many"
require "mongoid/relations/referenced/one"
require "mongoid/relations/reflections"
require "mongoid/relations/synchronization"
require "mongoid/relations/metadata"
require "mongoid/relations/macros"

module Mongoid # :nodoc:

  # All classes and modules under the relations namespace handle the
  # functionality that has to do with embedded and referenced (relational)
  # associations.
  module Relations
    extend ActiveSupport::Concern
    include Accessors
    include AutoSave
    include Cascading
    include Cyclic
    include Builders
    include Macros
    include Polymorphic
    include Reflections
    include Synchronization

    included do
      attr_accessor :metadata
    end

    # Determine if the document itself is embedded in another document via the
    # proper channels. (If it has a parent document.)
    #
    # @example Is the document embedded?
    #   address.embedded?
    #
    # @return [ true, false ] True if the document has a parent document.
    #
    # @since 2.0.0.rc.1
    def embedded?
      @embedded ||= (cyclic ? _parent.present? : self.class.embedded?)
    end

    # Determine if the document is part of an embeds_many relation.
    #
    # @example Is the document in an embeds many?
    #   address.embedded_many?
    #
    # @return [ true, false ] True if in an embeds many.
    #
    # @since 2.0.0.rc.1
    def embedded_many?
      metadata && metadata.macro == :embeds_many
    end

    # Determine if the document is part of an embeds_one relation.
    #
    # @example Is the document in an embeds one?
    #   address.embedded_one?
    #
    # @return [ true, false ] True if in an embeds one.
    #
    # @since 2.0.0.rc.1
    def embedded_one?
      metadata && metadata.macro == :embeds_one
    end

    # Determine if the document is part of an references_many relation.
    #
    # @example Is the document in a references many?
    #   post.referenced_many?
    #
    # @return [ true, false ] True if in a references many.
    #
    # @since 2.0.0.rc.1
    def referenced_many?
      metadata && metadata.macro == :references_many
    end

    # Determine if the document is part of an references_one relation.
    #
    # @example Is the document in a references one?
    #   address.referenced_one?
    #
    # @return [ true, false ] True if in a references one.
    #
    # @since 2.0.0.rc.1
    def referenced_one?
      metadata && metadata.macro == :references_one
    end

    # Convenience method for iterating through the loaded relations and
    # reloading them.
    #
    # @example Reload the relations.
    #   document.reload_relations
    #
    # @return [ Hash ] The relations metadata.
    #
    # @since 2.1.6
    def reload_relations
      relations.each_pair do |name, meta|
        if instance_variable_defined?("@#{name}")
          remove_instance_variable("@#{name}")
        end
      end
    end
  end
end
