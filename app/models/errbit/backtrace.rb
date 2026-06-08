# frozen_string_literal: true

module Errbit
  class Backtrace < ApplicationRecord
    IN_APP_PATH = %r{^(?:\[|/)PROJECT_ROOT\]?(?!(/vendor))/?}
    GEMS_PATH = %r{(?:\[|/)GEM_ROOT\]?/gems/([^/]+)}

    def self.find_or_create(lines)
      fingerprint = generate_fingerprint(lines)

      find_or_create_by!(fingerprint: fingerprint) do |backtrace|
        backtrace.lines = lines
      end
    rescue ActiveRecord::RecordNotUnique
      find_by!(fingerprint: fingerprint)
    end

    def self.generate_fingerprint(lines)
      Digest::SHA1.hexdigest(lines.map(&:to_s).join)
    end
  end
end
