# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_backtrace, class: "Errbit::Backtrace" do
    lines { [{"file" => "app/models/user.rb", "number" => 1, "method" => "call"}] }
    fingerprint { Errbit::Backtrace.generate_fingerprint(lines) }
  end
end
