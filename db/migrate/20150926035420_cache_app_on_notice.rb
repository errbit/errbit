class CacheAppOnNotice < Mongoid::Migration
  def self.up
    Notice.no_timeout.each do |n|
      n.app_id = n.try(:err).try(:problem).try(:app_id)
      n.save!
    end
  end

  def self.down
  end
end
