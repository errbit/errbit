# frozen_string_literal: true

class DestroyProblemsByAppJob < ActiveJob::Base
  queue_as :default

  def perform(app_id)
    app = App.find_by(id: app_id)
    ::ProblemDestroy.execute(app.problems)
  end
end
