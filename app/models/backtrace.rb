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

  def self.find_or_create(lines)
    fingerprint = generate_fingerprint(lines)

    where(fingerprint: generate_fingerprint(lines)).
      find_one_and_update(
        { '$setOnInsert' => { fingerprint: fingerprint, lines: lines } },
        { return_document: :after, upsert: true })
  end

  def raw=(raw)
    raw.compact.each do |raw_line|
      lines << BacktraceLine.new(BacktraceLineNormalizer.new(raw_line).call)
    end
  end

  private
  def generate_fingerprint
    self.fingerprint = self.class.generate_fingerprint(lines)
  end
end
