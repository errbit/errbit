# frozen_string_literal: true

module Errbit
  class ApplicationRecord < ActiveRecord::Base
    primary_abstract_class
  end
end
