# frozen_string_literal: true

module Errbit
  class App < ApplicationRecord
    has_many :watchers, class_name: "Errbit::Watcher", dependent: :destroy
  end
end
