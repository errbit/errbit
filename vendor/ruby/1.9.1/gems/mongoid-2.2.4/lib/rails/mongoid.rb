# encoding: utf-8
module Rails #:nodoc:
  module Mongoid #:nodoc:
    extend self

    # Create indexes for each model given the provided pattern and the class is
    # not embedded.
    #
    # @example Create all the indexes.
    #   Rails::Mongoid.create_indexes("app/models/**/*.rb")
    #
    # @param [ String ] pattern The file matching pattern.
    #
    # @return [ Array<String> ] The file names.
    #
    # @since 2.1.0
    def create_indexes(pattern)
      Dir.glob(pattern).each do |file|
        begin
          model = determine_model(file)
          if model
            model.create_indexes
            Logger.new($stdout).info("Generated indexes for #{model}")
          end
        rescue => e
        end
      end
    end

    # Use the application configuration to get every model and require it, so
    # that indexing and inheritance work in both development and production
    # with the same results.
    #
    # @example Load all the application models.
    #   Rails::Mongoid.load_models(app)
    #
    # @param [ Application ] app The rails application.
    def load_models(app)
      return unless ::Mongoid.preload_models
      app.config.paths["app/models"].each do |path|
        Dir.glob("#{path}/**/*.rb").sort.each do |file|
          load_model(file.gsub("#{path}/" , "").gsub(".rb", ""))
        end
      end
    end

    private

    # I don't want to mock out kernel for unit testing purposes, so added this
    # method as a convenience.
    #
    # @example Load the model.
    #   Mongoid.load_model("/mongoid/behaviour")
    #
    # @param [ String ] file The base filename.
    #
    # @since 2.0.0.rc.3
    def load_model(file)
      require_dependency(file)
    end

    # Given the provided file name, determine the model and return the class.
    #
    # @example Determine the model from the file.
    #   Rails::Mongoid.determine_model("app/models/person.rb")
    #
    # @param [ String ] file The filename.
    #
    # @return [ Class ] The model.
    #
    # @since 2.1.0
    def determine_model(file)
      model_path = file[0..-4].split('/')[2..-1]
      klass = model_path.map { |path| path.camelize }.join('::').constantize
      if klass.ancestors.include?(::Mongoid::Document) && !klass.embedded
        return klass
      end
    end
  end
end
