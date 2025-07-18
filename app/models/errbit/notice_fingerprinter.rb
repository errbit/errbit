# frozen_string_literal: true

module Errbit
  class NoticeFingerprinter < ApplicationRecord
    belongs_to :app, class_name: "Errbit::App", foreign_key: :errbit_app_id
  end
end
