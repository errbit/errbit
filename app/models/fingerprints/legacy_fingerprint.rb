require 'digest/md5'

class LegacyFingerprint < Fingerprint
  def to_s
    Digest::MD5.hexdigest(fingerprint_source)
  end

  def fingerprint_source
    location['method'] &&= sanitized_method_signature
  end

  private
  def sanitized_method_signature
    location['method'].gsub(/[0-9]+|FRAGMENT/, '#').gsub(/_+#/, '_#')
  end

  def location
    notice.backtrace.lines.first
  end
end
