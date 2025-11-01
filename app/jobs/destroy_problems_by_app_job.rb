# frozen_string_literal: true

class DestroyProblemsByAppJob < ApplicationJob
  queue_as :default

  # @param app_id [String]
  def perform(app_id)
    app = App.find_by(id: app_id)

    ProblemDestroy.execute(app.problems)
  end
end
