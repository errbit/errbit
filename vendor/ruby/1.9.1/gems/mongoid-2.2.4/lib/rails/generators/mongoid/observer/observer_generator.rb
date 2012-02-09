# encoding: utf-8
require "rails/generators/mongoid_generator"

module Mongoid #:nodoc:
  module Generators #:nodoc:
    class ObserverGenerator < Base #:nodoc:

      check_class_collision :suffix => "Observer"

      def create_observer_file
        template 'observer.rb.tt', File.join('app/models', class_path, "#{file_name}_observer.rb")
      end

      hook_for :test_framework
    end
  end
end
