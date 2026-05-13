# frozen_string_literal: true

module Errbit
  class Err < ApplicationRecord
    belongs_to :problem,
      class_name: "Errbit::Problem",
      foreign_key: :errbit_problem_id,
      inverse_of: :errs

    validates :fingerprint, presence: true

    delegate :app, :resolved?, to: :problem
  end
end
