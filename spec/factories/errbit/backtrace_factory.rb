# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_backtrace, class: "Errbit::Backtrace" do
    sequence(:lines) { |number| [{"file" => "app/models/user.rb", "number" => number, "method" => "call"}] }
    fingerprint { Errbit::Backtrace.generate_fingerprint(lines) }
  end
end
