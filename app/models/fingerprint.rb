class Fingerprint
  attr_reader :notice, :app_id

  def self.generate(notice, app_id)
    self.new(notice, app_id).to_s
  end

  def initialize(notice, app_id)
    @notice = notice
    @app_id = app_id
  end

  def to_s
    Digest::SHA1.hexdigest(fingerprint_source.to_s)
  end

  def fingerprint_source
    { message: normalized_message,
      backtrace: backtrace_fingerprint,
      error_class: notice.error_class,
      app_id: app_id }
  end

  # Take all the lines of the backtrace until we
  # reach an in-app line. From that point onward, take
  # only in-app lines.
  def backtrace_fingerprint
    line_in_fingerprint = ""
    found_an_in_app_line = false
    notice.backtrace.lines.each do |line|
      found_an_in_app_line = true if line.in_app?
      line_in_fingerprint << line.to_s if !found_an_in_app_line or line.in_app?
    end
    Digest::SHA1.hexdigest(line_in_fingerprint)
  end

  # Filter memory addresses out of object strings
  # example: "#<Object:0x007fa2b33d9458>" becomes "#<Object>"
  def normalized_message
    message = notice.message
      .gsub(/(#<.+?):0x[0-9a-f]+(>)/, '\1\2')
      .gsub(/\b0x[0-9a-f]+\b/, '0x__')
      .gsub(/\b[0-9]+(?:\.[0-9]+)? (seconds)/, '__ \1')
      .gsub(/(PG::[^\n]+ERROR:[^\n]*).*$/m, '\1')
  end

end
