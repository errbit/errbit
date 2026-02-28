# frozen_string_literal: true

module FeatureHelper
  def create_app_with_problem(app_attrs = {}, notice_attrs = {})
    app = create(:app, app_attrs)
    err = create(:err, problem: create(:problem, app: app))
    notice = create(:notice, app: app, err: err, **notice_attrs)
    {app: app, problem: err.problem, err: err, notice: notice}
  end
end

RSpec.configure do |config|
  config.include FeatureHelper, type: :feature
end
