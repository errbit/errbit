# frozen_string_literal: true

module Errbit
  class << self
    attr_writer :migrating

    def migrating?
      !!@migrating
    end
  end

  def self.table_name_prefix
    "errbit_"
  end
end
