module ErrsHelper
  
  def last_notice_at err
    err.last_notice_at || err.created_at
  end
  
end