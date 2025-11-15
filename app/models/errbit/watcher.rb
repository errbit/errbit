# frozen_string_literal: true

module Errbit
  class Watcher < ApplicationRecord
    belongs_to :user, class_name: "Errbit::User", foreign_key: :errbit_user_id, optional: true

    belongs_to :app, class_name: "Errbit::App", foreign_key: :errbit_app_id
  end
end
