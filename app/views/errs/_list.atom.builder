feed.updated(@problems.first.created_at)

for problem in @problems
  notice = problem.notices.first

  feed.entry(problem, :url => app_err_url(problem.app, problem)) do |entry|
    entry.title "[#{ problem.where }] #{problem.message.to_s.truncate(27)}"
    entry.author do |author|
      author.name "#{ problem.app.name } [#{ problem.environment }]"
    end
    if notice
      entry.summary(notice_atom_summary(notice), :type => "html")
    end
  end
end
