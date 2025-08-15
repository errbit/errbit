# frozen_string_literal: true

module Errbit
  class Version
    def initialize(ver, dev = false)
      @version = ver
      @dev = dev
    end

    def full_version
      full = [@version]
      if @dev
        full << "dev"
        full << source_version
      end
      full.compact.join("-")
    end

    def source_version
      source_version = ENV["SOURCE_VERSION"]
      source_version[0...8] if source_version.present?
    end

    class << self
      def to_s
        new("0.10.5", false).full_version
      end
    end
  end
end
