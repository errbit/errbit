class Fabrication::Sequencer

  DEFAULT = :_default

  def self.sequence(name=DEFAULT, start=0, &block)
    idx = sequences[name] ||= start
    if block_given?
      sequence_blocks[name] = block.to_proc
    else
      sequence_blocks[name] ||= lambda { |i| i }
    end.call(idx).tap do
      sequences[name] += 1
    end
  end

  def self.sequences
    @sequences ||= {}
  end

  def self.sequence_blocks
    @sequence_blocks ||= {}
  end
end
