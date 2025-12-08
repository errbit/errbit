# frozen_string_literal: true

class DestroyProblemsByAppJob < ApplicationJob
  queue_as :default

  # @param app [Errbit::App]
  def perform(app)
    ProblemDestroy.execute(app.problems)
  end
end
