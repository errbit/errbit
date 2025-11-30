# frozen_string_literal: true

FactoryBot.define do
  factory :backtrace do
  end
end

# Fabricator :backtrace do
#   lines(count: 99) do
#     {
#       number: rand(999),
#       file: "/path/to/file/#{SecureRandom.hex(4)}.rb",
#       method: ActiveSupport.methods.sample
#     }
#   end
# end
