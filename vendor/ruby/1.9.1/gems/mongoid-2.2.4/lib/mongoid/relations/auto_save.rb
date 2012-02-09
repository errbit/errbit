# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This module contains the behaviour for auto-saving relations in
    # different collections.
    module AutoSave
      extend ActiveSupport::Concern

      module ClassMethods #:nodoc:

        # Set up the autosave behaviour for references many and references one
        # relations. When the option is set to true, these relations will get
        # saved automatically when the parent is first saved, but not if the
        # parent already exists in the database.
        #
        # @example Set up autosave options.
        #   Person.autosave(metadata)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @since 2.0.0.rc.1
        def autosave(metadata)
          if metadata.autosave?
            set_callback :save, :after do |document|
              relation = document.send(metadata.name)
              if relation
                (relation.do_or_do_not(:in_memory) || relation.to_a).each do |doc|
                  doc.save
                end
              end
            end
          end
        end
      end
    end
  end
end
