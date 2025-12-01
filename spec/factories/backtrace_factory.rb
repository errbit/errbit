# frozen_string_literal: true

FactoryBot.define do
  factory :backtrace do
    lines do
      99.times.map do
        {
          number: rand(999),
          file: "/path/to/file/#{SecureRandom.hex(4)}.rb",
          method: ActiveSupport.methods.sample
        }
      end
    end
  end
end
