module PivotalTracker

  class Errors
    include Enumerable
    attr_reader :errors

    alias :messages :errors

    def initialize
      @errors = []
    end

    def each
      @errors.each do |error|
        yield error
      end
    end

    def empty?
      @errors.empty?
    end

    def add_from_xml(xml)
      Nokogiri::XML(xml).xpath("/errors/error").each do |error|
        @errors << error.text
      end
    end
  end

  module Validation

    def self.included(klass)
      klass.class_eval do
        if klass.instance_methods.include?(:create)
          alias_method :create_without_validations, :create
          alias_method :create, :create_with_validations
        end

        if klass.instance_methods.include?(:update)
          alias_method :update_without_validations, :update
          alias_method :update, :update_with_validations
        end
      end
    end

    def create_with_validations
      begin
        create_without_validations
      rescue RestClient::UnprocessableEntity => e
        errors.add_from_xml e.response
        self
      end
    end

    def update_with_validations(attrs={})
      begin
        update_without_validations attrs
      rescue RestClient::UnprocessableEntity => e
        errors.add_from_xml e.response
        self
      end
    end

    def errors
      @errors ||= Errors.new
    end
  end
end
