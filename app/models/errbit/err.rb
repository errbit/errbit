# frozen_string_literal: true

module Errbit
  class Err < ApplicationRecord
    belongs_to :problem,
      class_name: "Errbit::Problem",
      foreign_key: :errbit_problem_id,
      inverse_of: :errs

    has_many :notices,
      class_name: "Errbit::Notice",
      foreign_key: :errbit_err_id,
      inverse_of: :err,
      dependent: :destroy

    validates :fingerprint, presence: true

    delegate :app, :resolved?, to: :problem
  end
end
