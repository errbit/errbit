# encoding: utf-8
require 'rails/generators/mongoid_generator'

module Mongoid
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      desc "Creates a Mongoid configuration file at config/mongoid.yml"

      argument :database_name, :type => :string, :optional => true

      def self.source_root
        @_mongoid_source_root ||= File.expand_path("../templates", __FILE__)
      end

      def app_name
        Rails::Application.subclasses.first.parent.to_s.underscore
      end

      def create_config_file
        template 'mongoid.yml', File.join('config', "mongoid.yml")
      end

    end
  end
end
