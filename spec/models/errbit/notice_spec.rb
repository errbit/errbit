# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Notice, type: :model do
  it "sanitizes Mongo-unsafe hash keys before saving" do
    notice = create(:errbit_notice, request: {"$bad.key" => {"nested.key" => "value"}})

    expect(notice.request).to eq({"&#36;bad&#46;key" => {"nested&#46;key" => "value"}})
  end

  it "truncates long messages to the Mongo-compatible limit" do
    notice = create(:errbit_notice, message: "x" * 1_100)

    expect(notice.message.bytesize).to eq(Errbit::Notice::MESSAGE_LENGTH_LIMIT)
  end

  it "extracts host and environment from payload hashes" do
    notice = create(:errbit_notice)

    expect(notice.host).to eq("example.com")
    expect(notice.environment_name).to eq("production")
  end
end
