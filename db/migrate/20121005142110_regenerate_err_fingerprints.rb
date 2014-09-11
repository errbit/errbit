class RegenerateErrFingerprints < Mongoid::Migration
  def self.up
    Err.all.each do |err|
      if err.notices.any? && err.problem
        err.update_attribute(
          :fingerprint,
          Fingerprint.generate(err.notices.first, err.app.api_key)
        )
      end
    end
  end

  def self.down
  end
end
