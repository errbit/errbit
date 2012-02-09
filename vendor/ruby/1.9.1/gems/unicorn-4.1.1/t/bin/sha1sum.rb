#!/usr/bin/env ruby
# -*- encoding: binary -*-

# Reads from stdin and outputs the SHA1 hex digest of the input this is
# ONLY used as a last resort, our test code will try to use sha1sum(1),
# openssl(1), or gsha1sum(1) before falling back to using this.  We try
# all options first because we have a strong and healthy distrust of our
# Ruby abilities in general, and *especially* when it comes to
# understanding (and trusting the implementation of) Ruby 1.9 encoding.

require 'digest/sha1'
$stdout.sync = $stderr.sync = true
$stdout.binmode
$stdin.binmode
bs = 16384
digest = Digest::SHA1.new
if buf = $stdin.read(bs)
  begin
    digest.update(buf)
  end while $stdin.read(bs, buf)
end

$stdout.syswrite("#{digest.hexdigest}\n")
