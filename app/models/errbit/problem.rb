# frozen_string_literal: true

module Errbit
  class Problem < ApplicationRecord
    belongs_to :app
  end
end
