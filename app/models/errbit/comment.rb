# frozen_string_literal: true

module Errbit
  class Comment < ApplicationRecord
    belongs_to :user, class_name: "Errbit::User"

    # belongs_to :err, class_name: "Problem"
  end
end
