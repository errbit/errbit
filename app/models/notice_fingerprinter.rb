class NoticeFingerprinter
  include Mongoid::Document
  include Mongoid::Timestamps

  field :error_class, default: true, type: Boolean
  field :message, default: true, type: Boolean
  field :backtrace_lines, default: -1, type: Integer
  field :component, default: true, type: Boolean
  field :action, default: true, type: Boolean
  field :environment_name, default: true, type: Boolean
  field :source, type: String

  embedded_in :app
  embedded_in :site_config

  def generate(api_key, notice, backtrace)
    material = [ api_key ]
    material << notice.error_class if error_class
    material << notice.filtered_message if message
    material << notice.component if component
    material << notice.action if action
    material << notice.environment_name if environment_name

    if backtrace_lines < 0
      material << backtrace.lines
    else
      material << backtrace.lines.slice(0, backtrace_lines)
    end

    Digest::MD5.hexdigest(material.reduce('') { |c, m| c << m.to_s; c })
  end
end
