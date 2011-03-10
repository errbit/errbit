module ErrsHelper
  
  def last_notice_at err
    err.last_notice_at || err.created_at
  end

  def err_confirm
    Errbit::Config.confirm_resolve_err === false ? nil : 'Seriously?'
  end
end