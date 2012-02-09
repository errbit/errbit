# -*- encoding: binary -*-

# Copyright (c) 2005 Zed A. Shaw 
# You can redistribute it and/or modify it under the same terms as Ruby.
#
# Additional work donated by contributors.  See http://mongrel.rubyforge.org/attributions.html 
# for more information.

require 'test/test_helper'
require 'time'

include Unicorn

class ResponseTest < Test::Unit::TestCase
  include Unicorn::HttpResponse

  def test_httpdate
    before = Time.now.to_i - 1
    str = httpdate
    assert_kind_of(String, str)
    middle = Time.parse(str).to_i
    after = Time.now.to_i
    assert before <= middle
    assert middle <= after
  end

  def test_response_headers
    out = StringIO.new
    http_response_write(out, 200, {"X-Whatever" => "stuff"}, ["cool"])
    assert ! out.closed?

    assert out.length > 0, "output didn't have data"
  end

  def test_response_string_status
    out = StringIO.new
    http_response_write(out,'200', {}, [])
    assert ! out.closed?
    assert out.length > 0, "output didn't have data"
    assert_equal 1, out.string.split(/\r\n/).grep(/^Status: 200 OK/).size
  end

  def test_response_200
    io = StringIO.new
    http_response_write(io, 200, {}, [])
    assert ! io.closed?
    assert io.length > 0, "output didn't have data"
  end

  def test_response_with_default_reason
    code = 400
    io = StringIO.new
    http_response_write(io, code, {}, [])
    assert ! io.closed?
    lines = io.string.split(/\r\n/)
    assert_match(/.* Bad Request$/, lines.first,
                 "wrong default reason phrase")
  end

  def test_rack_multivalue_headers
    out = StringIO.new
    http_response_write(out,200, {"X-Whatever" => "stuff\nbleh"}, [])
    assert ! out.closed?
    assert_match(/^X-Whatever: stuff\r\nX-Whatever: bleh\r\n/, out.string)
  end

  # Even though Rack explicitly forbids "Status" in the header hash,
  # some broken clients still rely on it
  def test_status_header_added
    out = StringIO.new
    http_response_write(out,200, {"X-Whatever" => "stuff"}, [])
    assert ! out.closed?
    assert_equal 1, out.string.split(/\r\n/).grep(/^Status: 200 OK/i).size
  end

  def test_body_closed
    expect_body = %w(1 2 3 4).join("\n")
    body = StringIO.new(expect_body)
    body.rewind
    out = StringIO.new
    http_response_write(out,200, {}, body)
    assert ! out.closed?
    assert body.closed?
    assert_match(expect_body, out.string.split(/\r\n/).last)
  end

  def test_unknown_status_pass_through
    out = StringIO.new
    http_response_write(out,"666 I AM THE BEAST", {}, [] )
    assert ! out.closed?
    headers = out.string.split(/\r\n\r\n/).first.split(/\r\n/)
    assert %r{\AHTTP/\d\.\d 666 I AM THE BEAST\z}.match(headers[0])
    status = headers.grep(/\AStatus:/i).first
    assert status
    assert_equal "Status: 666 I AM THE BEAST", status
  end

end
