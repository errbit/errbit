# encoding: utf-8
module Mongoid #:nodoc:

  module Timestamps
    # This module handles the behaviour for setting up document updated at
    # timestamp.
    module Updated
      extend ActiveSupport::Concern

      included do
        field :updated_at, :type => Time

        set_callback :save, :before, :set_updated_at, :if => Proc.new { |doc|
          doc.new_record? || doc.changed?
        }

        unless methods.include? 'record_timestamps'
          class_attribute :record_timestamps
          self.record_timestamps = true
        end
      end

      # Update the updated_at field on the Document to the current time.
      # This is only called on create and on save.
      #
      # @example Set the updated at time.
      #   person.set_updated_at
      def set_updated_at
        self.updated_at = Time.now.utc unless self.updated_at_changed?
      end
    end
  end
end
