class RegenerateErrFingerprints < Mongoid::Migration
  def self.up
    Err.all.each do |err|
      if err.notices.any?
        fingerprint_source = {
          :backtrace   => err.notices.first.backtrace_id,
          :error_class => err.error_class,
          :component   => err.component,
          :action      => err.action,
          :environment => err.environment,
          :api_key     => err.app.api_key
        }
        fingerprint = Digest::SHA1.hexdigest(fingerprint_source.to_s)
        err.update_attribute(:fingerprint, fingerprint)
      end
    end
  end

  def self.down
  end
end
