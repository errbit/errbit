# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "errbit:migrate:users" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before do
    Rake::Task["errbit:migrate:users"].reenable
  end

  let(:task) { Rake::Task["errbit:migrate:users"] }

  it "creates an Errbit::User row for each Mongo User, linked by bson_id" do
    mongo_user = User.create!(
      email: "ported@example.com",
      name: "Ported",
      admin: true,
      password: "secret-password",
      password_confirmation: "secret-password"
    )

    expect { task.invoke }.to change(Errbit::User, :count).by(1)

    ar_user = Errbit::User.find_by!(bson_id: mongo_user._id.to_s)
    expect(ar_user.email).to eq("ported@example.com")
    expect(ar_user.name).to eq("Ported")
    expect(ar_user.admin).to eq(true)
    expect(ar_user.encrypted_password).to eq(mongo_user.encrypted_password)
    expect(ar_user.authentication_token).to eq(mongo_user.authentication_token)
  end

  it "preserves the original Mongo timestamps" do
    created = 3.years.ago.change(usec: 0)
    updated = 1.year.ago.change(usec: 0)

    mongo_user = User.create!(
      email: "old@example.com",
      name: "Old User",
      password: "secret-password"
    )
    mongo_user.update_attributes!(created_at: created, updated_at: updated)

    task.invoke

    ar_user = Errbit::User.find_by!(bson_id: mongo_user._id.to_s)
    expect(ar_user.created_at.to_i).to eq(created.to_i)
    expect(ar_user.updated_at.to_i).to eq(updated.to_i)
  end

  it "is idempotent — re-running updates the existing record" do
    mongo_user = User.create!(
      email: "twice@example.com",
      name: "Twice",
      password: "secret-password"
    )

    task.invoke
    Rake::Task["errbit:migrate:users"].reenable

    mongo_user.update!(name: "Renamed")
    expect { task.invoke }.not_to change(Errbit::User, :count)

    expect(Errbit::User.find_by!(bson_id: mongo_user._id.to_s).name).to eq("Renamed")
  end

  it "skips devise validations so users without passwords (e.g. github-only) still migrate" do
    mongo_user = User.new(
      email: "gh@example.com",
      name: "GH User",
      github_login: "gh-handle"
    )
    mongo_user.save(validate: false)

    expect { task.invoke }.to change(Errbit::User, :count).by(1)

    ar_user = Errbit::User.find_by!(bson_id: mongo_user._id.to_s)
    expect(ar_user.github_login).to eq("gh-handle")
  end
end
