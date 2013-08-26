class ExtractBacktraces < Mongoid::Migration
  def self.up
    say "It could take long time (hours if you have many Notices)"
    Notice.unscoped.all.each do |notice|
      next if notice.backtrace.present? || notice['backtrace'].nil?
      backtrace = Backtrace.find_or_create(:raw => notice['backtrace'] || [])
      notice.backtrace = backtrace
      notice['backtrace'] = nil
      notice.save!
    end
    say "run `db.repairDatabase()` (in mongodb console) to recover deleted space"
  end

  def self.down
  end
end