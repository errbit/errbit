module ProblemSearchHelper
  def default_from_date
    if Problem.count > 0
      Problem.order_by(first_notice_at: :asc).first.first_notice_at.to_date
    else
      default_until_date
    end
  end

  def default_until_date
    Date.today
  end
end
