require './test/lib_read_write'
require 'tempfile'

class TestUnixServerReadClientWrite < Test::Unit::TestCase
  def setup
    tmp = Tempfile.new('kgio_unix')
    @path = tmp.path
    File.unlink(@path)
    tmp.close rescue nil
    @srv = Kgio::UNIXServer.new(@path)
    @wr = Kgio::UNIXSocket.new(@path)
    @rd = @srv.kgio_tryaccept
  end

  include LibReadWriteTest
end

