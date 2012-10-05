class BacktraceLine
  include Mongoid::Document
  IN_APP_REGEXP = %r{^\[PROJECT_ROOT\]\/(?!(vendor))}

  field :number, :type => Integer
  field :file
  field :method

  embedded_in :backtrace

  scope :in_app, where(:file => IN_APP_REGEXP)

  def to_s
    "#{file}:#{number}"
  end

  def in_app?
    !!(file =~ IN_APP_REGEXP)
  end
end

