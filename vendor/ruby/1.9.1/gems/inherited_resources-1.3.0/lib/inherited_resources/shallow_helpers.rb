module InheritedResources
  # Shallow provides a functionality that goes on pair with Rails' shallow.
  # It is very similar to "optional" but it actually finds all the parents
  # resources instead of leaving them blank. Consider the following example:
  #
  #   belongs_to :post, :shallow => true do
  #     belongs_to :comment
  #   end
  #
  # When accessed as /comments/1, Inherited Resources will automatically get
  # the post resource so both objects are actually accessible through the views.
  #
  # However, when using optional, Inherited Resources wouldn't actually bother
  # with finding the parent object.
  module ShallowHelpers
    private

      def symbols_for_association_chain #:nodoc:
        parent_symbols = parents_symbols.dup
        instance = nil

        if id = params[:id]
          finder_method = resources_configuration[:self][:finder] || :find
          instance      = self.resource_class.send(finder_method, id)
        elsif parents_symbols.size > 1
          config         = resources_configuration[parent_symbols.pop]
          finder_method  = config[:finder] || :find
          instance       = config[:parent_class].send(finder_method, params[config[:param]])
        end

        load_parents(instance, parent_symbols) if instance
        parents_symbols
      end

      def load_parents(instance, parent_symbols)
        parent_symbols.reverse.each do |parent|
          instance = instance.send(parent)
          config   = resources_configuration[parent]
          params[config[:param]] = instance.to_param
        end
      end
  end
end
