module Lighthouse
  class Base < ActiveResource::Base
    def self.inherited(base)
      Lighthouse.resources << base
      class << base        
        attr_accessor :site_format
        
        def site_with_update
          Lighthouse.update_site(self)
          site_without_update
        end
        alias_method_chain :site, :update
      end
      base.site_format = '%s'
      super
      Lighthouse.update_token_header(base)
      Lighthouse.update_auth(base)
    end
  end
end
