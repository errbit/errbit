# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Watcher, type: :model do
  it { expect(subject).to be_an(Errbit::ApplicationRecord) }

  it { expect(subject).to belong_to(:user).class_name("Errbit::User").optional }

  it { expect(subject).to belong_to(:app).class_name("Errbit::App") }
end
