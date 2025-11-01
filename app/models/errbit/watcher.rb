# frozen_string_literal: true

module Errbit
  class Watcher < ApplicationRecord
    belongs_to :user, optional: true

    belongs_to :app
  end
end
