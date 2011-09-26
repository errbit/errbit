module ErrsHelper
  def last_notice_at(problem)
    problem.last_notice_at || problem.created_at
  end

  def err_confirm
    Errbit::Config.confirm_resolve_err === false ? nil : 'Seriously?'
  end

  def trucated_err_message(problem)
    msg = truncate(problem.message, :length => 300)
    # Insert invisible unicode characters so that firefox can emulate 'word-wrap: break-word' CSS
    msg.scan(/.{5}/).join("&#8203;").html_safe
  end
end

