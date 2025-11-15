# frozen_string_literal: true

module Errbit
  class Watcher < ApplicationRecord
    belongs_to :user, class_name: "Errbit::User", optional: true

    belongs_to :app, class_name: "Errbit::App"
  end
end
