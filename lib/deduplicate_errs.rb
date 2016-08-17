class DeduplicateErrs

  class << self
    delegate :execute, to: "self.new"
  end

  def execute(errs=Err.all)
    Err.transaction do
      dedup_errs!(errs)
      destroy_errs_with_no_notices!
      destroy_problems_with_no_errs!
    end
  end

  def dedup_errs!(errs)
    query = errs.select("errs.id, errs.fingerprint").to_sql

    errs_by_fingerprint =  Err.connection.select_rows(query) \
      .each_with_object({}) { |(id, fingerprint), map| (map[fingerprint] ||= []).push(id.to_i) }
      .select { |fingerprint, err_ids| err_ids.length > 1 }

    puts "\e[33;1m#{errs_by_fingerprint.values.flatten.count}\e[0;33m Errs share \e[1m#{errs_by_fingerprint.keys.count}\e[0;33m fingerprints. Orphaning \e[1m#{errs_by_fingerprint.values.flatten.count - errs_by_fingerprint.keys.count}\e[0;33m Errs.\e[0m"

    errs_by_fingerprint.each do |fingerprint, err_ids|
      Notice.where(err_id: err_ids).update_all(err_id: err_ids.first)
    end
  end

  def destroy_errs_with_no_notices!
    errs_with_no_notices = Err.joins(<<-SQL).where("notice_count.count IS NULL OR notice_count.count=0").pluck(:id)
      LEFT OUTER JOIN (SELECT err_id, COUNT(notices.id) "count" FROM notices GROUP BY err_id) "notice_count"
      ON notice_count.err_id=errs.id
    SQL
    puts "\e[33;1m#{errs_with_no_notices.count}\e[0;33m Errs have no notices. Deleting the them.\e[0m"
    Err.where(id: errs_with_no_notices).delete_all
  end

  def destroy_problems_with_no_errs!
    problems_with_no_errs = Problem.joins(<<-SQL).where("err_count.count IS NULL OR err_count.count=0").pluck(:id)
      LEFT OUTER JOIN (SELECT problem_id, COUNT(errs.id) "count" FROM errs GROUP BY problem_id) "err_count"
      ON err_count.problem_id=problems.id
    SQL
    puts "\e[33;1m#{problems_with_no_errs.count}\e[0;33m Problems have no errs. Deleting the them.\e[0m"
    Problem.where(id: problems_with_no_errs).delete_all
  end

end
