# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SQL HTML runtime", type: :request do
  let(:user) { create(:errbit_user, admin: true) }

  before do
    sign_in user
  end

  it "renders the apps index and show pages" do
    app = create(:errbit_app, name: "SQL App")

    get apps_path
    expect(response).to be_successful

    get new_app_path
    expect(response).to be_successful

    get app_path(app)
    expect(response).to be_successful

    get edit_app_path(app)
    expect(response).to be_successful
  end

  it "renders problem index and show pages" do
    app = create(:errbit_app)
    problem = create(:errbit_problem, app: app)
    err = create(:errbit_err, problem: problem)
    create(:errbit_notice, app: app, err: err)

    get app_problems_path(app)
    expect(response).to be_successful

    get app_problem_path(app, problem)
    expect(response).to be_successful
  end
end
