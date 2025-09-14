# frozen_string_literal: true

module Errbit
  class User < ApplicationRecord
    devise(*Errbit::Config.devise_modules)

    validates :name, presence: true
    validates :github_login, uniqueness: {allow_nil: true}
  end
end
