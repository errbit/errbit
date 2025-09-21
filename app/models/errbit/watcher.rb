# frozen_string_literal: true

module Errbit
  class Watcher < ApplicationRecord
    belongs_to :user, optional: true
  end
end
