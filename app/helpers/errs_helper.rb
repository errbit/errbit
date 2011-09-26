module ErrsHelper
  def last_notice_at(problem)
    problem.last_notice_at || problem.created_at
  end

  def err_confirm
    Errbit::Config.confirm_resolve_err === false ? nil : 'Seriously?'
  end
end

