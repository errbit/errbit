dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'happymapper')

file_contents = File.read(dir + '/../spec/fixtures/statuses.xml')

class User
  include HappyMapper
  
  element :id, Integer
  element :name, String
  element :screen_name, String
  element :location, String
  element :description, String
  element :profile_image_url, String
  element :url, String
  element :protected, Boolean
  element :followers_count, Integer
end

class Status
  include HappyMapper
  
  element :id, Integer
  element :text, String
	element :created_at, Time
	element :source, String
	element :truncated, Boolean
	element :in_reply_to_status_id, Integer
	element :in_reply_to_user_id, Integer
	element :favorited, Boolean
	has_one :user, User
end

statuses = Status.parse(file_contents)
statuses.each do |status|
  puts status.user.name, status.user.screen_name, status.text, status.source, ''
end