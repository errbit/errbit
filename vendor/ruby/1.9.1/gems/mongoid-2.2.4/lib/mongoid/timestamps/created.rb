# encoding: utf-8
module Mongoid #:nodoc:

  module Timestamps
    # This module handles the behaviour for setting up document created at
    # timestamp.
    module Created
      extend ActiveSupport::Concern

      included do
        field :created_at, :type => Time

        set_callback :create, :before, :set_created_at

        unless methods.include? 'record_timestamps'
          class_attribute :record_timestamps
          self.record_timestamps = true
        end
      end

      # Update the created_at field on the Document to the current time. This is
      # only called on create.
      #
      # @example Set the created at time.
      #   person.set_created_at
      def set_created_at
        self.created_at = Time.now.utc if !created_at
      end
    end
  end
end
