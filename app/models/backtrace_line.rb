class BacktraceLine
  include Mongoid::Document

  field :number, :type => Integer
  field :file
  field :method

  embedded_in :backtrace
end

