# frozen_string_literal: true

class BSON::ObjectId
  def as_json(*_args)
    to_s
  end
end
