# frozen_string_literal: true

atom_feed do |feed|
  feed.title("Errbit notices at #{root_url}")
  render "problems/list", feed: feed
end
