class RefingerprintErrs

  class << self
    delegate :execute, :analyze, to: "self.new"
  end

  def analyze
    errs = Err.count
    errs_with_no_notices = []
    errs_with_mismatched_notices = []
    map = {}
    Err.includes(:problem, :notices => {:backtrace => :lines}).find_each(batch_size: 300) do |err|
      fingerprints = err.notices.map { |notice| Fingerprint.generate(notice, err.problem.app_id) }

      if fingerprints.empty?
        errs_with_no_notices << err
        next
      end

      errs_with_mismatched_notices << err if fingerprints.uniq.count > 1

      map[err.fingerprint] = fingerprints.first
    end

    err_collisions_before = errs - map.keys.uniq.count
    err_collisions_after = errs - map.values.uniq.count

    puts "\n" * 4
    puts "Errs\e[90m......................................\e[34;1m#{errs.to_s.rjust(5)}\e[0m"
    puts "Errs with no notices\e[90m......................\e[34m#{errs_with_no_notices.count.to_s.rjust(5)}\e[0m"
    puts "Errs with mismatched notices\e[90m..............\e[34m#{errs_with_mismatched_notices.count.to_s.rjust(5)}\e[0m"
    puts "Errs with the same fingerprint (before)\e[90m...\e[34m#{err_collisions_before.to_s.rjust(5)}\e[0m"
    puts "Errs with the same fingerprint (after)\e[90m....\e[34m#{err_collisions_after.to_s.rjust(5)}\e[0m"

    # Errs...................................... 3042
    # Errs with no notices......................  307
    # Errs with mismatched notices..............  191
    # Errs with the same fingerprint (before)...  379
    # Errs with the same fingerprint (after)....  681
  end

  def execute
    refingerprint_errs!
    dedup_errs!
    destroy_errs_with_no_notices!
    destroy_problems_with_no_errs!
  end

  def refingerprint_errs!
    Err.includes(:problem, :notice => {:backtrace => :lines}).find_each do |err|
      next if err.notice.nil?
      err.update_column :fingerprint, Fingerprint.generate(err.notice, err.problem.app_id)
    end
  end

  def dedup_errs!
    errs_by_fingerprint =  Err.connection.select_rows("SELECT id, fingerprint FROM errs") \
      .each_with_object({}) { |(id, fingerprint), map| (map[fingerprint] ||= []).push(id.to_i) }
      .select { |fingerprint, err_ids| err_ids.length > 1 }

    puts "\e[33;1m#{errs_by_fingerprint.values.flatten.count}\e[0;33m Errs share \e[1m#{errs_by_fingerprint.keys.count}\e[0;33m fingerprints. Orphaning \e[1m#{errs_by_fingerprint.values.flatten.count - errs_by_fingerprint.keys.count}\e[0;33m Errs.\e[0m"
    errs_by_fingerprint.each do |fingerprint, err_ids|
      Notice.where(err_id: err_ids).update_all(err_id: err_ids.first)
    end
  end

  def destroy_errs_with_no_notices!
    errs_with_no_notices = Err.includes(:notices).select { |err| err.notices.count.zero? }
    puts "\e[33;1m#{errs_with_no_notices.count}\e[0;33m Errs have no notices. Deleting the them.\e[0m"
    Err.where(id: errs_with_no_notices.map(&:id)).delete_all
  end

  def destroy_problems_with_no_errs!
    problems_with_no_errs = Problem.includes(:errs).select { |problem| problem.errs.count.zero? }
    puts "\e[33;1m#{problems_with_no_errs.count}\e[0;33m Problems have no errs. Deleting the them.\e[0m"
    # ProblemDestroy.execute(problems_with_no_errs)
  end

  # !todo: handle notices

end
