# frozen_string_literal: true

module Errbit
  class App < ApplicationRecord
    has_many :watchers, class_name: "Errbit::Watcher", foreign_key: :errbit_app_id, dependent: :destroy
  end
end
