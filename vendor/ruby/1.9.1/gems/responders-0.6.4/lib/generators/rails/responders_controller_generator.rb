require 'rails/generators/rails/scaffold_controller/scaffold_controller_generator'

module Rails
  module Generators
    class RespondersControllerGenerator < ScaffoldControllerGenerator
      source_root File.expand_path("../templates", __FILE__)

    protected

      def flash?
        !ApplicationController.responder.ancestors.include?(Responders::FlashResponder)
      end
    end
  end
end