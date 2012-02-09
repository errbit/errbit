# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:

        # Binding class for references_one relations.
        class One < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # @example Bind the document.
          #   person.game.bind(:continue => true)
          #   person.game = Game.new
          #
          # @since 2.0.0.rc.1
          def bind
            unless binding?
              binding do
                target.you_must(metadata.foreign_key_setter, base.id)
                target.send(metadata.inverse_setter, base)
                if metadata.type
                  target.you_must(metadata.type_setter, base.class.model_name)
                end
              end
            end
          end
          alias :bind_one :bind

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the document.
          #   person.game.unbind(:continue => true)
          #   person.game = nil
          #
          # @since 2.0.0.rc.1
          def unbind
            unless binding?
              binding do
                target.you_must(metadata.foreign_key_setter, nil)
                target.send(metadata.inverse_setter, nil)
                if metadata.type
                  target.you_must(metadata.type_setter, nil)
                end
              end
            end
          end
          alias :unbind_one :unbind
        end
      end
    end
  end
end
