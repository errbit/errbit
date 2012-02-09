module RSpec
  module Core
    module DSL
      def describe(*args, &example_group_block)
        RSpec::Core::ExampleGroup.describe(*args, &example_group_block).register
      end
    end
  end
end

include RSpec::Core::DSL
