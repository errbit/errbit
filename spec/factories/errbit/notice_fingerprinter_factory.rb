# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_notice_fingerprinter, class: "Errbit::NoticeFingerprinter" do
    association :app, factory: :errbit_app
  end
end
