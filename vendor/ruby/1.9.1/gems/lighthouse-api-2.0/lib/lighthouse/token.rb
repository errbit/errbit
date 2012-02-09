module Lighthouse
  class Token < Base
    def save
      raise Error, "Cannot modify Tokens from the API"
    end
  end
end
