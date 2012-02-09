module InheritedResources

  # = singleton
  #
  # Singletons are usually used in associations which are related through has_one
  # and belongs_to. You declare those associations like this:
  #
  #   class ManagersController < InheritedResources::Base
  #     belongs_to :project, :singleton => true
  #   end
  #
  # But in some cases, like an AccountsController, you have a singleton object
  # that is not necessarily associated with another:
  #
  #   class AccountsController < InheritedResources::Base
  #     defaults :singleton => true
  #   end
  #
  # Besides that, you should overwrite the methods :resource and :build_resource
  # to make it work properly:
  #
  #   class AccountsController < InheritedResources::Base
  #     defaults :singleton => true
  #
  #     protected
  #       def resource
  #         @current_user.account
  #       end
  #
  #       def build_resource(attributes = {})
  #         Account.new(attributes)
  #       end
  #   end
  #
  # When you have a singleton controller, the action index is removed.
  #
  module SingletonHelpers

    protected

      # Singleton methods does not deal with collections.
      #
      def collection
        nil
      end

      # Overwrites how singleton deals with resource.
      #
      # If you are going to overwrite it, you should notice that the
      # end_of_association_chain here is not the same as in default belongs_to.
      #
      #   class TasksController < InheritedResources::Base
      #     belongs_to :project
      #   end
      #
      # In this case, the association chain would be:
      #
      #   Project.find(params[:project_id]).tasks
      #
      # So you would just have to call find(:all) at the end of association
      # chain. And this is what happened.
      #
      # In singleton controllers:
      #
      #   class ManagersController < InheritedResources::Base
      #     belongs_to :project, :singleton => true
      #   end
      #
      # The association chain will be:
      #
      #   Project.find(params[:project_id])
      #
      # So we have to call manager on it, not find.
      #
      def resource
        get_resource_ivar || set_resource_ivar(end_of_association_chain.send(resource_instance_name))
      end

    private

      # Returns the appropriated method to build the resource.
      #
      def method_for_association_build #:nodoc:
        :"build_#{resource_instance_name}"
      end

      # Sets the method_for_association_chain to nil. See <tt>resource</tt>
      # above for more information.
      #
      def method_for_association_chain #:nodoc:
        nil
      end

  end
end
