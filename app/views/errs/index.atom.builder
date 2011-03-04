atom_feed do |feed|
  feed.title("Errbit notices at #{root_url}")
  feed.updated(@errs.first.created_at)

  for err in @errs
    feed.entry(err, :url => app_err_url(err.app, err)) do |entry|
      entry.title "[#{ err.environment }] #{ err.app.name } at \"#{ err.where }\""
      entry.summary(err.notices.first.try(:message))
    end
  end
end
