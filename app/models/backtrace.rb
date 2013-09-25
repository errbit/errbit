class Backtrace
  include Mongoid::Document
  include Mongoid::Timestamps

  field :fingerprint
  index :fingerprint => 1

  has_many :notices
  has_one :notice

  embeds_many :lines, :class_name => "BacktraceLine"

  after_initialize :generate_fingerprint

  delegate :app, :to => :notice

  def self.find_or_create(attributes = {})
    new(attributes).similar || create(attributes)
  end

  def similar
    Backtrace.where(:fingerprint => fingerprint).first
  end

  def raw=(raw)
    raw.compact.each do |raw_line|
      lines << BacktraceLine.new(BacktraceLineNormalizer.new(raw_line).call)
    end
  end

  private
  def generate_fingerprint
    self.fingerprint = Digest::SHA1.hexdigest(lines.map(&:to_s).join)
  end

end
