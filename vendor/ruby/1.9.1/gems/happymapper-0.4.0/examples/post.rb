dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'happymapper')

file_contents = File.read(dir + '/../spec/fixtures/posts.xml')

class Post
  include HappyMapper
  
  attribute :href, String
  attribute :hash, String
  attribute :description, String
  attribute :tag, String
  attribute :time, DateTime
  attribute :others, Integer
  attribute :extended, String
end

posts = Post.parse(file_contents)
posts.each { |post| puts post.description, post.href, post.extended, '' }