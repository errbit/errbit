module PivotalTracker
  class Attachment
    include HappyMapper

    tag 'attachment'

    element :id, Integer
    element :filename, String
    element :description, String
    element :uploaded_by, String
    element :uploaded_at, DateTime
    element :url, String
    element :status, String

  end
end
