atom_feed do |feed|
  feed.title("Errbit notices for #{h @app.name} at #{root_url}")
  render :partial => "errs/list", :locals => {:feed => feed}
end
