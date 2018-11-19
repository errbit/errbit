# frozen_string_literal: true

module Errbit
  class Version
    def full_version
      [
        '0.8.0',
        'dev',
        source_version
      ].compact.join('-')
    end

    def source_version
      source_version = ENV['SOURCE_VERSION']
      source_version[0...8] if source_version.present?
    end
  end

  VERSION = Version.new.full_version
end
