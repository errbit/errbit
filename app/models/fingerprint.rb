require 'digest/sha1'

class Fingerprint
  attr_reader :notice, :api_key
  
  def self.generate(notice, api_key)
    self.new(notice, api_key).to_s
  end
  
  def initialize(notice, api_key)
    @notice = notice
    @api_key = api_key
  end
  
  
  
  def to_s
    Digest::SHA1.hexdigest(fingerprint_source.to_s)
  end
  
  def fingerprint_source
    # Find the first backtrace line with a file and line number.
    if line = notice.backtrace.lines.detect {|l| l.number.present? && l.file.present? }
      # If line exists, only use file and number.
      file_or_message = "#{line.file}:#{line.number}"
    else
      # If no backtrace, use error message
      file_or_message = notice.message
    end

    {
      :file_or_message => file_or_message,
      :error_class => notice.error_class,
      :component => notice.component || 'unknown',
      :action => notice.action,
      :environment => notice.environment_name || 'development',
      :api_key => api_key
    }
  end
  
end
