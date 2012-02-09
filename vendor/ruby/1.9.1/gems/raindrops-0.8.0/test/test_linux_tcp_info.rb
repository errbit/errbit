# -*- encoding: binary -*-
require 'test/unit'
require 'tempfile'
require 'raindrops'
require 'socket'
require 'pp'
$stderr.sync = $stdout.sync = true
class TestLinuxTCP_Info < Test::Unit::TestCase

  TEST_ADDR = ENV['UNICORN_TEST_ADDR'] || '127.0.0.1'

  # Linux kernel commit 5ee3afba88f5a79d0bff07ddd87af45919259f91
  TCP_INFO_useful_listenq = `uname -r`.strip >= '2.6.24'

  def test_tcp_server
    s = TCPServer.new(TEST_ADDR, 0)
    rv = Raindrops::TCP_Info.new s
    c = TCPSocket.new TEST_ADDR, s.addr[1]
    tmp = Raindrops::TCP_Info.new s
    TCP_INFO_useful_listenq and assert_equal 1, tmp.unacked

    assert_equal 0, rv.unacked
    a = s.accept
    tmp = Raindrops::TCP_Info.new s
    assert_equal 0, tmp.unacked
    ensure
      c.close if c
      a.close if a
      s.close
  end

  def test_accessors
    s = TCPServer.new TEST_ADDR, 0
    tmp = Raindrops::TCP_Info.new s
    tcp_info_methods = tmp.methods - Object.new.methods
    assert tcp_info_methods.size >= 32
    tcp_info_methods.each do |m|
      val = tmp.__send__ m
      assert_kind_of Integer, val
      assert val >= 0
    end
    ensure
      s.close
  end

  def test_tcp_server_delayed
    delay = 0.010
    delay_ms = (delay * 1000).to_i
    s = TCPServer.new(TEST_ADDR, 0)
    c = TCPSocket.new TEST_ADDR, s.addr[1]
    c.syswrite "."
    sleep(delay * 1.2)
    a = s.accept
    i = Raindrops::TCP_Info.new(a)
    assert i.last_data_recv >= delay_ms, "#{i.last_data_recv} < #{delay_ms}"
    ensure
      c.close if c
      a.close if a
      s.close
  end
end
