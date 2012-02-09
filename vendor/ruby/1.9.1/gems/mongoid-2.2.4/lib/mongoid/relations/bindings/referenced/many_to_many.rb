# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:

        # Binding class for all references_and_referenced_in_many relations.
        class ManyToMany < Binding

          # Binds a single document with the inverse relation. Used
          # specifically when appending to the proxy.
          #
          # @example Bind one document.
          #   person.preferences.bind_one(preference)
          #
          # @param [ Document ] doc The single document to bind.
          #
          # @since 2.0.0.rc.1
          def bind_one(doc)
            unless binding?
              binding do
                inverse_keys = doc.you_must(metadata.inverse_foreign_key)
                inverse_keys.push(base.id) if inverse_keys
                base.synced[metadata.foreign_key] = true
                doc.synced[metadata.inverse_foreign_key] = true
              end
            end
          end

          # Unbind a single document.
          #
          # @example Unbind the document.
          #   person.preferences.unbind_one(document)
          #
          # @since 2.0.0.rc.1
          def unbind_one(doc)
            unless binding?
              binding do
                base.send(metadata.foreign_key).delete_one(doc.id)
                inverse_keys = doc.you_must(metadata.inverse_foreign_key)
                inverse_keys.delete_one(base.id) if inverse_keys
                base.synced[metadata.foreign_key] = true
                doc.synced[metadata.inverse_foreign_key] = true
              end
            end
          end
        end
      end
    end
  end
end
