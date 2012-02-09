require 'tempfile'
require './test/lib_server_accept'

class TestKgioUNIXServer < Test::Unit::TestCase

  def setup
    tmp = Tempfile.new('kgio_unix')
    @path = tmp.path
    File.unlink(@path)
    tmp.close rescue nil
    @srv = Kgio::UNIXServer.new(@path)
    @host = '127.0.0.1'
  end

  def client_connect
    UNIXSocket.new(@path)
  end

  include LibServerAccept
end
