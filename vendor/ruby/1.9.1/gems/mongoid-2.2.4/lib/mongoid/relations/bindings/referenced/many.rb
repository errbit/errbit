# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Referenced #:nodoc:

        # Binding class for references_many relations.
        class Many < Binding

          # Binds a single document with the inverse relation. Used
          # specifically when appending to the proxy.
          #
          # @example Bind one document.
          #   person.posts.bind_one(post)
          #
          # @param [ Document ] doc The single document to bind.
          #
          # @since 2.0.0.rc.1
          def bind_one(doc)
            unless binding?
              binding do
                doc.you_must(metadata.foreign_key_setter, base.id)
                if metadata.type
                  doc.you_must(metadata.type_setter, base.class.model_name)
                end
                doc.send(metadata.inverse_setter, base)
              end
            end
          end

          # Unbind a single document.
          #
          # @example Unbind the document.
          #   person.posts.unbind_one(document)
          #
          # @param [ Document ] document The document to unbind.
          #
          # @since 2.0.0.rc.1
          def unbind_one(doc)
            unless binding?
              binding do
                doc.you_must(metadata.foreign_key_setter, nil)
                if metadata.type
                  doc.you_must(metadata.type_setter, nil)
                end
                doc.send(metadata.inverse_setter, nil)
              end
            end
          end
        end
      end
    end
  end
end
