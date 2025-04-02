# frozen_string_literal: true

VCR.configure do |c|
  c.cassette_library_dir = Rails.root.join("spec/cassettes")
  c.hook_into :webmock
  c.ignore_localhost = true
  c.default_cassette_options = {
    decode_compressed_response: true,
    allow_unused_http_interactions: false
  }
end
