# encoding: utf-8
module Mongoid #:nodoc:
  # This module is for hooking in to +ActiveModel+s serialization to let
  # configuring the ability to include the root in JSON happen from the Mongoid
  # config.
  module JSON
    extend ActiveSupport::Concern

    # We need to redefine where the JSON configuration is getting defined,
    # similar to +ActiveRecord+.
    included do
      undef_method :include_root_in_json
      delegate :include_root_in_json, :to => ::Mongoid
    end
  end
end
