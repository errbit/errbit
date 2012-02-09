module Mongoid
  module Document
    # Used in conjunction with fields_for to build a form element for the
    # destruction of this association. Always returns false because Mongoid
    # only supports immediate deletion of associations.
    #
    # See ActionView::Helpers::FormHelper::fields_for for more info.
    def _destroy
      false
    end
  end
end
