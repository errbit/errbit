#!/usr/bin/env ruby
require 'rubygems'
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'redmine_client'

RedmineClient::Base.configure do
  self.site = 'http://localhost:3000'
  self.user = 'admin'
  self.password = 'test'
end

puts "Found #{RedmineClient::Issue.find(:all).count} issues"
