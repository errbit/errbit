# Whenever base is required load the dumb responder since it's used inside actions.
require 'inherited_resources/blank_slate'

module InheritedResources
  # Base helpers for InheritedResource work. Some methods here can be overwriten
  # and you will need to do that to customize your controllers from time to time.
  #
  module BaseHelpers

    protected

      # This is how the collection is loaded.
      #
      # You might want to overwrite this method if you want to add pagination
      # for example. When you do that, don't forget to cache the result in an
      # instance_variable:
      #
      #   def collection
      #     @projects ||= end_of_association_chain.paginate(params[:page]).all
      #   end
      #
      def collection
        get_collection_ivar || begin
          c = end_of_association_chain
          set_collection_ivar(c.respond_to?(:scoped) ? c.scoped : c.all)
        end
      end

      # This is how the resource is loaded.
      #
      # You might want to overwrite this method when you are using permalink.
      # When you do that, don't forget to cache the result in an
      # instance_variable:
      #
      #   def resource
      #     @project ||= end_of_association_chain.find_by_permalink!(params[:id])
      #   end
      #
      # You also might want to add the exclamation mark at the end of the method
      # because it will raise a 404 if nothing can be found. Otherwise it will
      # probably render a 500 error message.
      #
      def resource
        get_resource_ivar || set_resource_ivar(end_of_association_chain.send(method_for_find, params[:id]))
      end

      # This method is responsable for building the object on :new and :create
      # methods. If you overwrite it, don't forget to cache the result in an
      # instance variable.
      #
      def build_resource
        get_resource_ivar || set_resource_ivar(end_of_association_chain.send(method_for_build, *resource_params))
      end

      # Responsible for saving the resource on :create method. Overwriting this
      # allow you to control the way resource is saved. Let's say you have a
      # PassworsController who is responsible for finding an user by email and
      # sent password instructions for him. Instead of overwriting the entire
      # :create method, you could do something:
      #
      #   def create_resource(object)
      #     object.send_instructions_by_email
      #   end
      #
      def create_resource(object)
        object.save
      end

      # Responsible for updating the resource in :update method. This allow you
      # to handle how the resource is gona be updated, let's say in a different
      # way then the usual :update_attributes:
      #
      #   def update_resource(object, attributes)
      #     object.reset_password!(attributes)
      #   end
      #
      def update_resource(object, attributes)
        object.update_attributes(*attributes)
      end

      # Handle the :destroy method for the resource. Overwrite it to call your
      # own method for destroing the resource, as:
      #
      #   def destroy_resource(object)
      #     object.cancel
      #   end
      #
      def destroy_resource(object)
        object.destroy
      end

      # This class allows you to set a instance variable to begin your
      # association chain. For example, usually your projects belongs to users
      # and that means that they belong to the current logged in user. So you
      # could do this:
      #
      #   def begin_of_association_chain
      #     @current_user
      #   end
      #
      # So every time we instantiate a project, we will do:
      #
      #   @current_user.projects.build(params[:project])
      #   @current_user.projects.find(params[:id])
      #
      # The variable set in begin_of_association_chain is not sent when building
      # urls, so this is never going to happen when calling resource_url:
      #
      #   project_url(@current_user, @project)
      #
      # If the user actually scopes the url, you should use belongs_to method
      # and declare that projects belong to user.
      #
      def begin_of_association_chain
        nil
      end

      # Returns if the controller has a parent. When only base helpers are loaded,
      # it's always false and should not be overwriten.
      #
      def parent?
        false
      end

      # Returns the association chain, with all parents (does not include the
      # current resource).
      #
      def association_chain
        @association_chain ||=
          symbols_for_association_chain.inject([begin_of_association_chain]) do |chain, symbol|
            chain << evaluate_parent(symbol, resources_configuration[symbol], chain.last)
          end.compact.freeze
      end

      # Overwrite this method to provide other interpolation options when
      # the flash message is going to be set.
      #
      # def interpolation_options
      #    { }
      # end

    private

      # Adds the given object to association chain.
      def with_chain(object)
        association_chain + [ object ]
      end

      # Fast accessor to resource_collection_name
      #
      def resource_collection_name #:nodoc:
        self.resources_configuration[:self][:collection_name]
      end

      # Fast accessor to resource_instance_name
      #
      def resource_instance_name #:nodoc:
        self.resources_configuration[:self][:instance_name]
      end

      def resource_request_name
        self.resources_configuration[:self][:request_name]
      end

      # This methods gets your begin_of_association_chain, join it with your
      # parents chain and returns the scoped association.
      #
      def end_of_association_chain #:nodoc:
        if chain = association_chain.last
          if method_for_association_chain
            apply_scopes_if_available(chain.send(method_for_association_chain))
          else
            # This only happens when we specify begin_of_association_chain in
            # a singletion controller without parents. In this case, the chain
            # is exactly the begin_of_association_chain which is already an
            # instance and then not scopable.
            chain
          end
        else
          apply_scopes_if_available(resource_class)
        end
      end

      # Returns the appropriated method to build the resource.
      #
      def method_for_build #:nodoc:
        (begin_of_association_chain || parent?) ? method_for_association_build : :new
      end

      # Returns the name of the method used for build the resource in cases
      # where we have a parent. This is overwritten in singleton scenarios.
      #
      def method_for_association_build
        :build
      end

      # Returns the name of the method to be called, before returning the end
      # of the association chain. This is overwriten by singleton cases
      # where no method for association chain is called.
      #
      def method_for_association_chain #:nodoc:
        resource_collection_name
      end

      # Returns finder method for instantiate resource by params[:id]
      def method_for_find
        resources_configuration[:self][:finder] || :find
      end

      # Get resource ivar based on the current resource controller.
      #
      def get_resource_ivar #:nodoc:
        instance_variable_get("@#{resource_instance_name}")
      end

      # Set resource ivar based on the current resource controller.
      #
      def set_resource_ivar(resource) #:nodoc:
        instance_variable_set("@#{resource_instance_name}", resource)
      end

      # Get collection ivar based on the current resource controller.
      #
      def get_collection_ivar #:nodoc:
        instance_variable_get("@#{resource_collection_name}")
      end

      # Set collection ivar based on the current resource controller.
      #
      def set_collection_ivar(collection) #:nodoc:
        instance_variable_set("@#{resource_collection_name}", collection)
      end

      # Used to allow to specify success and failure within just one block:
      #
      #   def create
      #     create! do |success, failure|
      #       failure.html { redirect_to root_url }
      #     end
      #   end
      #
      # It also calculates the response url in case a block without arity is
      # given and returns it. Otherwise returns nil.
      #
      def respond_with_dual_blocks(object, options, &block) #:nodoc:
        args = (with_chain(object) << options)

        case block.try(:arity)
          when 2
            respond_with(*args) do |responder|
              blank_slate = InheritedResources::BlankSlate.new
              if object.errors.empty?
                block.call(responder, blank_slate)
              else
                block.call(blank_slate, responder)
              end
            end
          when 1
            respond_with(*args, &block)
          else
            options[:location] = block.call if block
            respond_with(*args)
        end
      end

      # Hook to apply scopes. By default returns only the target_object given.
      # It's extend by HasScopeHelpers.
      #
      def apply_scopes_if_available(target_object) #:nodoc:
        respond_to?(:apply_scopes) ? apply_scopes(target_object) : target_object
      end

      # Symbols chain in base helpers return nothing. This is later overwriten
      # by belongs_to and can be complex in polymorphic cases.
      #
      def symbols_for_association_chain #:nodoc:
        []
      end

      # URL to redirect to when redirect implies resource url.
      def smart_resource_url
        url = nil
        if respond_to? :show
          url = resource_url rescue nil
        end
        url ||= smart_collection_url
      end

      # URL to redirect to when redirect implies collection url.
      def smart_collection_url
        url = nil
        if respond_to? :index
          url ||= collection_url rescue nil
        end
        if respond_to? :parent
          url ||= parent_url rescue nil
        end
        url ||= root_url rescue nil
      end

      # extract attributes from params
      def resource_params
        rparams = [params[resource_request_name] || params[resource_instance_name] || {}]
        rparams << as_role if role_given?
        rparams
      end
      
      # checking if role given
      def role_given?
        self.resources_configuration[:self][:role].present?
      end
      
      # getting role for mass-asignment
      def as_role
         { :as => self.resources_configuration[:self][:role] }
      end
  end
end

