# encoding: utf-8
require "rails/generators/mongoid_generator"

module Mongoid #:nodoc:
  module Generators #:nodoc:
    class ModelGenerator < Base #:nodoc:

      desc "Creates a Mongoid model"
      argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"

      check_class_collision

      class_option :timestamps, :type => :boolean
      class_option :parent,     :type => :string, :desc => "The parent class for the generated model"
      class_option :versioning, :type => :boolean, :default => false, :desc => "Enable mongoid versioning"

      def create_model_file
        template "model.rb.tt", File.join("app/models", class_path, "#{file_name}.rb")
      end

      hook_for :test_framework
    end
  end
end
