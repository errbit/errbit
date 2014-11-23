class Backtrace < ActiveRecord::Base

  has_many :notices
  has_one :notice
  has_many :lines, class_name: "BacktraceLine", order: "created_at ASC"

  after_initialize :generate_fingerprint, if: :new_record?

  delegate :app, to: :notice

  def self.find_or_create(attributes = {})
    new(attributes).similar || create(attributes)
  end

  def similar
    Backtrace.where(fingerprint: fingerprint).first
  end

  def raw=(raw)
    raw.compact.each do |raw_line|
      lines << BacktraceLine.new(BacktraceLineNormalizer.new(raw_line).call)
    end
  end

  def includes?(file_and_method)
    filename, methodname = file_and_method.split("#")
    where(file: "[PROJECT_ROOT]/#{filename}", method: methodname).exists?
  end

private

  def generate_fingerprint
    self.fingerprint = Digest::SHA1.hexdigest(lines.join)
  end

end
