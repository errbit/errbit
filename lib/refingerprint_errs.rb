require "progressbar"

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
  end

  def execute
    pbar = ProgressBar.new("fingerprints", Err.count)
    Err.includes(:problem, :notice => {:backtrace => :lines}).find_each do |err|
      next if err.notice.nil?
      err.update_column :fingerprint, Fingerprint.generate(err.notice, err.problem.app_id)
      pbar.inc
    end
    pbar.finish
  end

end
