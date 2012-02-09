module InheritedResources
  class Responder < ActionController::Responder
    include Responders::FlashResponder
    include Responders::HttpCacheResponder
  end
end