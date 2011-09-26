module ErrsHelper
  def last_notice_at(problem)
    problem.last_notice_at || problem.created_at
  end

  def err_confirm
    Errbit::Config.confirm_resolve_err === false ? nil : 'Seriously?'
  end

  def trucated_err_message(problem)
    unless (msg = problem.message).blank?
      # Truncate & insert invisible chars so that firefox can emulate 'word-wrap: break-word' CSS rule
      truncate(msg, :length => 300).scan(/.{1,5}/).join("&#8203;").html_safe
    end
  end
end

