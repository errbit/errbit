# encoding: utf-8
module Mongoid #:nodoc:

  # This module contains logic for easy access to objects that have a lifecycle
  # on the current thread.
  module Threaded
    extend self

    # Begins a assigning block.
    #
    # @example Begin the assign.
    #   Threaded.begin_assign
    #
    # @return [ true ] Always true.
    #
    # @since 2.1.9
    def begin_assign
      assign_stack.push(true)
    end

    # Begins a binding block.
    #
    # @example Begin the bind.
    #   Threaded.begin_bind
    #
    # @return [ true ] Always true.
    #
    # @since 2.1.9
    def begin_bind
      bind_stack.push(true)
    end

    # Begins a building block.
    #
    # @example Begin the build.
    #   Threaded.begin_build
    #
    # @return [ true ] Always true.
    #
    # @since 2.1.9
    def begin_build
      build_stack.push(true)
    end

    # Begins a creating block.
    #
    # @example Begin the create.
    #   Threaded.begin_create
    #
    # @return [ true ] Always true.
    #
    # @since 2.1.9
    def begin_create
      create_stack.push(true)
    end

    # Begin validating a document on the current thread.
    #
    # @example Begin validation.
    #   Threaded.begin_validate(doc)
    #
    # @param [ Document ] document The document to validate.
    #
    # @since 2.1.9
    def begin_validate(document)
      validations_for(document.class).push(document.id)
    end

    # Is the current thread in assigning mode?
    #
    # @example Is the thread in assigning mode?
    #   Threaded.assigning?
    #
    # @return [ true, false ] If the thread is in assigning mode?
    #
    # @since 2.1.0
    def assigning?
      !assign_stack.empty?
    end

    # Is the current thread in binding mode?
    #
    # @example Is the thread in binding mode?
    #   Threaded.binding?
    #
    # @return [ true, false ] If the thread is in binding mode?
    #
    # @since 2.1.0
    def binding?
      !bind_stack.empty?
    end

    # Is the current thread in building mode?
    #
    # @example Is the thread in building mode?
    #   Threaded.building?
    #
    # @return [ true, false ] If the thread is in building mode?
    #
    # @since 2.1.0
    def building?
      !build_stack.empty?
    end

    # Is the current thread in creating mode?
    #
    # @example Is the thread in creating mode?
    #   Threaded.creating?
    #
    # @return [ true, false ] If the thread is in creating mode?
    #
    # @since 2.1.0
    def creating?
      !create_stack.empty?
    end

    # Get the assign stack for the current thread. Is simply an array of calls
    # to Mongoid's assigning method.
    #
    # @example Get the assign stack.
    #   Threaded.assign_stack
    #
    # @return [ Array ] The array of assign calls.
    #
    # @since 2.1.9
    def assign_stack
      Thread.current[:"[mongoid]:assign-stack"] ||= []
    end

    # Get the bind stack for the current thread. Is simply an array of calls
    # to Mongoid's binding method.
    #
    # @example Get the bind stack.
    #   Threaded.bind_stack
    #
    # @return [ Array ] The array of bind calls.
    #
    # @since 2.1.9
    def bind_stack
      Thread.current[:"[mongoid]:bind-stack"] ||= []
    end

    # Get the build stack for the current thread. Is simply an array of calls
    # to Mongoid's building method.
    #
    # @example Get the build stack.
    #   Threaded.build_stack
    #
    # @return [ Array ] The array of build calls.
    #
    # @since 2.1.9
    def build_stack
      Thread.current[:"[mongoid]:build-stack"] ||= []
    end

    # Get the create stack for the current thread. Is simply an array of calls
    # to Mongoid's creating method.
    #
    # @example Get the create stack.
    #   Threaded.create_stack
    #
    # @return [ Array ] The array of create calls.
    #
    # @since 2.1.9
    def create_stack
      Thread.current[:"[mongoid]:create-stack"] ||= []
    end

    # Clear out all the safety options set using the safely proxy.
    #
    # @example Clear out the options.
    #   Threaded.clear_safety_options!
    #
    # @return [ nil ] nil
    #
    # @since 2.1.0
    def clear_safety_options!
      Thread.current[:"[mongoid]:safety-options"] = nil
    end

    # Exit the assigning block.
    #
    # @example Exit the assigning block.
    #   Threaded.exit_assign
    #
    # @return [ true ] The last element in the stack.
    #
    # @since 2.1.9
    def exit_assign
      assign_stack.pop
    end

    # Exit the binding block.
    #
    # @example Exit the binding block.
    #   Threaded.exit_bind
    #
    # @return [ true ] The last element in the stack.
    #
    # @since 2.1.9
    def exit_bind
      bind_stack.pop
    end

    # Exit the building block.
    #
    # @example Exit the building block.
    #   Threaded.exit_build
    #
    # @return [ true ] The last element in the stack.
    #
    # @since 2.1.9
    def exit_build
      build_stack.pop
    end

    # Exit the creating block.
    #
    # @example Exit the creating block.
    #   Threaded.exit_create
    #
    # @return [ true ] The last element in the stack.
    #
    # @since 2.1.9
    def exit_create
      create_stack.pop
    end

    # Exit validating a document on the current thread.
    #
    # @example Exit validation.
    #   Threaded.exit_validate(doc)
    #
    # @param [ Document ] document The document to validate.
    #
    # @since 2.1.9
    def exit_validate(document)
      validations_for(document.class).delete_one(document.id)
    end

    # Get the identity map off the current thread.
    #
    # @example Get the identity map.
    #   Threaded.identity_map
    #
    # @return [ IdentityMap ] The identity map.
    #
    # @since 2.1.0
    def identity_map
      Thread.current[:"[mongoid]:identity-map"] ||= IdentityMap.new
    end

    # Get the insert consumer from the current thread.
    #
    # @example Get the insert consumer.
    #   Threaded.insert
    #
    # @return [ Object ] The batch insert consumer.
    #
    # @since 2.1.0
    def insert
      Thread.current[:"[mongoid]:insert-consumer"]
    end

    # Set the insert consumer on the current thread.
    #
    # @example Set the insert consumer.
    #   Threaded.insert = consumer
    #
    # @param [ Object ] consumer The insert consumer.
    #
    # @return [ Object ] The insert consumer.
    #
    # @since 2.1.0
    def insert=(consumer)
      Thread.current[:"[mongoid]:insert-consumer"] = consumer
    end

    # Get the safety options for the current thread.
    #
    # @example Get the safety options.
    #   Threaded.safety_options
    #
    # @return [ Hash ] The current safety options.
    #
    # @since 2.1.0
    def safety_options
      Thread.current[:"[mongoid]:safety-options"]
    end

    # Set the safety options on the current thread.
    #
    # @example Set the safety options.
    #   Threaded.safety_options = { :fsync => true }
    #
    # @param [ Hash ] options The safety options.
    #
    # @return [ Hash ] The safety options.
    #
    # @since 2.1.0
    def safety_options=(options)
      Thread.current[:"[mongoid]:safety-options"] = options
    end

    # Get the mongoid scope stack for chained criteria.
    #
    # @example Get the scope stack.
    #   Threaded.scope_stack
    #
    # @return [ Hash ] The scope stack.
    #
    # @since 2.1.0
    def scope_stack
      Thread.current[:"[mongoid]:scope-stack"] ||= {}
    end

    # Get the update consumer from the current thread.
    #
    # @example Get the update consumer.
    #   Threaded.update
    #
    # @return [ Object ] The atomic update consumer.
    #
    # @since 2.1.0
    def update_consumer(klass)
      Thread.current[:"[mongoid][#{klass}]:update-consumer"]
    end

    # Set the update consumer on the current thread.
    #
    # @example Set the update consumer.
    #   Threaded.update = consumer
    #
    # @param [ Object ] consumer The update consumer.
    #
    # @return [ Object ] The update consumer.
    #
    # @since 2.1.0
    def set_update_consumer(klass, consumer)
      Thread.current[:"[mongoid][#{klass}]:update-consumer"] = consumer
    end

    # Is the document validated on the current thread?
    #
    # @example Is the document validated?
    #   Threaded.validated?(doc)
    #
    # @param [ Document ] document The document to check.
    #
    # @return [ true, false ] If the document is validated.
    #
    # @since 2.1.9
    def validated?(document)
      validations_for(document.class).include?(document.id)
    end

    # Get all validations on the current thread.
    #
    # @example Get all validations.
    #   Threaded.validations
    #
    # @return [ Hash ] The current validations.
    #
    # @since 2.1.9
    def validations
      Thread.current[:"[mongoid]:validations"] ||= {}
    end

    # Get all validations on the current thread for the class.
    #
    # @example Get all validations.
    #   Threaded.validations_for(Person)
    #
    # @param [ Class ] The class to check.
    #
    # @return [ Array ] The current validations.
    #
    # @since 2.1.9
    def validations_for(klass)
      validations[klass] ||= []
    end
  end
end
