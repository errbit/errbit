# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Embedded #:nodoc:

        # Binding class for embeds_one relations.
        class One < Binding

          # Binds the base object to the inverse of the relation. This is so we
          # are referenced to the actual objects themselves on both sides.
          #
          # This case sets the metadata on the inverse object as well as the
          # document itself.
          #
          # @example Bind the document.
          #   person.name.bind(:continue => true)
          #   person.name = Name.new
          #
          # @param [ Hash ] options The options to pass through.
          #
          # @option options [ true, false ] :continue Do we continue binding?
          # @option options [ true, false ] :binding Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def bind
            target.parentize(base)
            unless binding?
              binding do
                target.do_or_do_not(metadata.inverse_setter(target), base)
              end
            end
          end
          alias :bind_one :bind

          # Unbinds the base object and the inverse, caused by setting the
          # reference to nil.
          #
          # @example Unbind the document.
          #   person.name.unbind(:continue => true)
          #   person.name = nil
          #
          # @param [ Hash ] options The options to pass through.
          #
          # @option options [ true, false ] :continue Do we continue unbinding?
          # @option options [ true, false ] :binding Are we in build mode?
          #
          # @since 2.0.0.rc.1
          def unbind
            unless binding?
              binding do
                target.do_or_do_not(metadata.inverse_setter(target), nil)
              end
            end
          end
          alias :unbind_one :unbind
        end
      end
    end
  end
end
