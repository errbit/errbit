# frozen_string_literal: true

module Errbit
  class App < ApplicationRecord
    has_many :watchers, dependent: :destroy
  end
end
