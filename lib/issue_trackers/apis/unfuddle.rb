require 'active_resource'

module Unfuddle
  class Ticket < ActiveResource::Base
    self.format = :xml
  end

  def self.config(account, username, password)
    Unfuddle::Ticket.site = "https://#{account}.unfuddle.com/api/v1/projects/:project_id"
    Unfuddle::Ticket.user = username
    Unfuddle::Ticket.password = password
  end
end
