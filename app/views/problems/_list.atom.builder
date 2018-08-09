feed.updated(problems.first.try(:created_at) || Time.now)

problems.each do |problem|
  notice = problem.notices.first

  feed.entry(problem, :url => app_problem_url(problem.app.to_param, problem.to_param)) do |entry|
    entry.title "[#{ problem.where }] #{problem.message.to_s.truncate(27)}"
    entry.author do |author|
      author.name "#{ problem.app.name } [#{ problem.environment }]"
    end
    if notice
      entry.summary(notice_atom_summary(notice), :type => "html")
    end
  end
end
