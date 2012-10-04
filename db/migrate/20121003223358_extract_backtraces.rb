class ExtractBacktraces < Mongoid::Migration
  def self.up
    Notice.unscoped.all.each do |notice|
      backtrace = Backtrace.find_or_create(:raw => notice['backtrace'])
      notice.backtrace = backtrace
      notice['backtrace'] = nil
      notice.save!
    end
  end

  def self.down
  end
end
