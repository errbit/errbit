# frozen_string_literal: true

# Workaround for json gem that loads before json-schema and fails
require "json-schema"

JSON::Validator.use_multi_json = false
