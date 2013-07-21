atom_feed do |feed|
  feed.title("Errbit notices for #{h app.name} at #{root_url}")
  render "problems/list", :feed => feed
end
