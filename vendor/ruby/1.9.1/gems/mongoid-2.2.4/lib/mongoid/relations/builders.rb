# encoding: utf-8
require "mongoid/relations/builder"
require "mongoid/relations/nested_builder"
require "mongoid/relations/builders/embedded/in"
require "mongoid/relations/builders/embedded/many"
require "mongoid/relations/builders/embedded/one"
require "mongoid/relations/builders/nested_attributes/one"
require "mongoid/relations/builders/nested_attributes/many"
require "mongoid/relations/builders/referenced/in"
require "mongoid/relations/builders/referenced/many"
require "mongoid/relations/builders/referenced/many_to_many"
require "mongoid/relations/builders/referenced/one"

module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This module is responsible for defining the build and create methods used
    # in one to one relations.
    #
    # @example Methods that get created.
    #
    #   class Person
    #     include Mongoid::Document
    #     embeds_one :name
    #   end
    #
    #   # The following methods get created:
    #   person.build_name({ :first_name => "Durran" })
    #   person.create_name({ :first_name => "Durran" })
    #
    # @since 2.0.0.rc.1
    module Builders
      extend ActiveSupport::Concern

      # Execute a block in building mode.
      #
      # @example Execute in building mode.
      #   building do
      #     relation.push(doc)
      #   end
      #
      # @return [ Object ] The return value of the block.
      #
      # @since 2.1.0
      def building
        Threaded.begin_build
        yield
      ensure
        Threaded.exit_build
      end

      module ClassMethods #:nodoc:

        # Defines a builder method for an embeds_one relation. This is
        # defined as #build_name.
        #
        # @example
        #   Person.builder("name")
        #
        # @param [ String, Symbol ] name The name of the relation.
        #
        # @return [ Class ] The class being set up.
        #
        # @since 2.0.0.rc.1
        def builder(name, metadata)
          tap do
            define_method("build_#{name}") do |*args|
              document = Factory.build(metadata.klass, args.first || {})
              building do
                send("#{name}=", document)
              end
            end
          end
        end

        # Defines a creator method for an embeds_one relation. This is
        # defined as #create_name. After the object is built it will
        # immediately save.
        #
        # @example
        #   Person.creator("name")
        #
        # @param [ String, Symbol ] name The name of the relation.
        #
        # @return [ Class ] The class being set up.
        #
        # @since 2.0.0.rc.1
        def creator(name)
          tap do
            define_method("create_#{name}") do |*args|
              send("build_#{name}", *args).tap { |doc| doc.save }
            end
          end
        end
      end
    end
  end
end
