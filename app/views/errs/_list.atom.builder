feed.updated(@errs.first.created_at)

for err in @errs
  notice = err.notices.first

  feed.entry(err, :url => app_err_url(err.app, err)) do |entry|
    entry.title "[#{ err.where }] #{err.message.to_s.truncate(27)}"
    entry.author do |author|
      author.name "#{ err.app.name } [#{ err.environment }]"
    end
    if notice
      entry.summary(notice_atom_summary(notice), :type => "html")
    end
  end
end
