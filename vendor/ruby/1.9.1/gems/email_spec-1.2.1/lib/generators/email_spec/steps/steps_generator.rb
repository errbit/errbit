# This generator adds email steps to the step definitions directory
require 'rails/generators'

module EmailSpec
  class StepsGenerator < Rails::Generators::Base
    def generate
      copy_file 'email_steps.rb', 'features/step_definitions/email_steps.rb'
    end

    def self.source_root
      File.join(File.dirname(__FILE__), 'templates')
    end
  end
end