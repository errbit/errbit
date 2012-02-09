# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:

        # Binding class for all referenced_in relations.
        class In < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # @example Bind the documents.
          #   game.person.bind(:continue => true)
          #   game.person = Person.new
          #
          # @since 2.0.0.rc.1
          def bind
            unless binding?
              binding do
                inverse = metadata.inverse(target)
                base.you_must(metadata.foreign_key_setter, target.id)
                if metadata.inverse_type
                  base.you_must(metadata.inverse_type_setter, target.class.model_name)
                end
                if inverse
                  inverse_metadata = metadata.inverse_metadata(target)
                  if inverse_metadata != metadata && !inverse_metadata.nil?
                    base.metadata = inverse_metadata
                    if base.referenced_many?
                      target.send(inverse).push(base)
                    else
                      target.do_or_do_not(metadata.inverse_setter(target), base)
                    end
                  end
                end
              end
            end
          end
          alias :bind_one :bind

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the document.
          #   game.person.unbind(:continue => true)
          #   game.person = nil
          #
          # @since 2.0.0.rc.1
          def unbind
            unless binding?
              binding do
                inverse = metadata.inverse(target)
                base.you_must(metadata.foreign_key_setter, nil)
                if metadata.inverse_type
                  base.you_must(metadata.inverse_type_setter, nil)
                end
                if inverse
                  if base.referenced_many?
                    target.send(inverse).delete(base)
                  else
                    target.send(metadata.inverse_setter(target), nil)
                  end
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
