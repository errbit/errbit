# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::NoticeDecorator, type: :decorator do
  it "decorates an Errbit::Notice" do
    notice = create(:errbit_notice)

    expect(described_class.new(notice).object).to eq(notice)
  end

  it "decorates the backtrace association" do
    notice = create(:errbit_notice)

    decorated = described_class.new(notice)

    expect(decorated.backtrace).to be_a(Errbit::BacktraceDecorator)
  end
end
