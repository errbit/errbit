# frozen_string_literal: true

module Errbit
  VERSION = [
    '0.8.0',
    'dev',
    ENV.fetch('SOURCE_VERSION', '')[0..8]
  ].compact.join('-')
end
