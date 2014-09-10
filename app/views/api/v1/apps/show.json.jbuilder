json.(@app, :id, :name)
json.errors @app.problems do |json, problem|
  json.(problem, :message, :last_noticed_at, :notices_count)
end
