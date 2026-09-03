# frozen_string_literal: true

module Errbit
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
