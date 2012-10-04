class BacktraceLine
  include Mongoid::Document

  field :number, :type => Integer
  field :file
  field :method

  embedded_in :backtrace

  def fingerprint
    [number, file, method].join
  end
end

