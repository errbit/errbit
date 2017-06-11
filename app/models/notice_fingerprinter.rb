class NoticeFingerprinter
  include Mongoid::Document
  include Mongoid::Timestamps

  field :error_class, default: true, type: Boolean
  field :message, default: true, type: Boolean
  field :message_patterns, type: String
  field :backtrace_lines, default: -1, type: Integer
  field :component, default: true, type: Boolean
  field :action, default: true, type: Boolean
  field :environment_name, default: true, type: Boolean
  field :source, type: String

  embedded_in :app
  embedded_in :site_config

  def generate(api_key, notice, backtrace)
    material = [api_key]
    material << notice.error_class if error_class
    material << replace_by_patterns(notice.filtered_message, message_patterns) if message
    material << notice.component if component
    material << notice.action if action
    material << notice.environment_name if environment_name

    # Sometimes backtrace is nil
    if backtrace
      if backtrace_lines < 0
        material << backtrace.lines
      else
        material << backtrace.lines.slice(0, backtrace_lines)
      end
    end

    Digest::MD5.hexdigest(material.map(&:to_s).join)
  end

  private

  def replace_by_patterns(input, message_patterns)
    message_patterns.split("\n").each do |pattern|
      input = input.gsub(Regexp.new(pattern.strip), pattern.strip)
    end unless message_patterns.nil?
    input
  end
end
