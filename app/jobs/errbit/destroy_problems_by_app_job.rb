# frozen_string_literal: true

module Errbit
  class DestroyProblemsByAppJob < ApplicationJob
    queue_as :default

    # @param app_id [Integer]
    def perform(app_id)
      app = Errbit::App.find_by(id: app_id)
      return unless app

      Errbit::ProblemDestroy.execute(app.problems)
    end
  end
end
