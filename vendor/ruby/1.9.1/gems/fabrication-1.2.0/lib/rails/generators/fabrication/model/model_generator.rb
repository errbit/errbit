require 'rails/generators/named_base'

module Fabrication
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"
      class_option :dir, :type => :string, :default => "spec/fabricators", :desc => "The directory where the fabricators should go"
      class_option :extension, :type => :string, :default => "rb", :desc => "file extension name"

      def create_fabrication_file
        template 'fabricator.rb', File.join(options[:dir], "#{singular_table_name}_fabricator.#{options[:extension].to_s}")
      end

      def self.source_root
        @_fabrication_source_root ||= File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
      end
    end
  end
end
