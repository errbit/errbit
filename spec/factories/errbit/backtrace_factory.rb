# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_backtrace, class: "Errbit::Backtrace" do
    sequence(:lines) do |n|
      [
        {"number" => "123", "file" => "/some/path/to.rb", "method" => "abc_#{n}"},
        {"number" => "345", "file" => "/path/to.rb", "method" => "dowhat"}
      ]
    end

    fingerprint { Errbit::Backtrace.generate_fingerprint(lines) }
  end
end
