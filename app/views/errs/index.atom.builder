atom_feed do |feed|
  feed.title("Errbit notices at #{root_url}")
  render "errs/list", :feed => feed
end
