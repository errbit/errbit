require Rails.root.join('lib/overrides/hoptoad_notifier/hoptoad_notifier')

class BSON::ObjectId
  def as_json(*args)
    to_s
  end
end
