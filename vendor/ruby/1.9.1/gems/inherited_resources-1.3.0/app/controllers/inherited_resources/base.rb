module InheritedResources
  # = Base
  #
  # This is the base class that holds all actions. If you see the code for each
  # action, they are quite similar to Rails default scaffold.
  #
  # To change your base behavior, you can overwrite your actions and call super,
  # call <tt>default</tt> class method, call <<tt>actions</tt> class method
  # or overwrite some helpers in the base_helpers.rb file.
  #
  class Base < ::ApplicationController
    # Overwrite inherit_resources to add specific InheritedResources behavior.
    def self.inherit_resources(base)
      base.class_eval do
        include InheritedResources::Actions
        include InheritedResources::BaseHelpers
        extend  InheritedResources::ClassMethods
        extend  InheritedResources::UrlHelpers

        # Add at least :html mime type
        respond_to :html if self.mimes_for_respond_to.empty?
        self.responder = InheritedResources::Responder

        helper_method :resource, :collection, :resource_class, :association_chain,
                      :resource_instance_name, :resource_collection_name,
                      :resource_url, :resource_path,
                      :collection_url, :collection_path,
                      :new_resource_url, :new_resource_path,
                      :edit_resource_url, :edit_resource_path,
                      :parent_url, :parent_path,
                      :smart_resource_url, :smart_collection_url

        self.class_attribute :resource_class, :instance_writer => false unless self.respond_to? :resource_class
        self.class_attribute :parents_symbols,  :resources_configuration, :instance_writer => false

        protected :resource_class, :parents_symbols, :resources_configuration,
          :resource_class?, :parents_symbols?, :resources_configuration?
      end
    end

    inherit_resources(self)
  end
end