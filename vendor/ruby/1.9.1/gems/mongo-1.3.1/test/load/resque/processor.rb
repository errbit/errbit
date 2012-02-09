require 'logger'

class Processor
  @queue = :processor

  def self.connection
    @log ||= Logger.new(STDOUT)
    @con ||= Mongo::Connection.new("localhost", 27017)
  end

  def self.perform(n)
    begin
    100.times do |n|
      self.connection['resque']['docs'].insert({:n => n, :data => "0" * 1000}, :safe => true)
    end

    5.times do |n|
      num = rand(100)
      self.connection['resque']['docs'].find({:n => {"$gt" => num}}).limit(1).to_a
    end
    rescue => e
      @log.warn(e.inspect)
    end
  end

end
