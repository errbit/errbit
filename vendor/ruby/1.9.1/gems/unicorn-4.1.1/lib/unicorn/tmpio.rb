# -*- encoding: binary -*-
# :stopdoc:
require 'tmpdir'

# some versions of Ruby had a broken Tempfile which didn't work
# well with unlinked files.  This one is much shorter, easier
# to understand, and slightly faster.
class Unicorn::TmpIO < File

  # creates and returns a new File object.  The File is unlinked
  # immediately, switched to binary mode, and userspace output
  # buffering is disabled
  def self.new
    fp = begin
      super("#{Dir::tmpdir}/#{rand}", RDWR|CREAT|EXCL, 0600)
    rescue Errno::EEXIST
      retry
    end
    unlink(fp.path)
    fp.binmode
    fp.sync = true
    fp
  end

  # for easier env["rack.input"] compatibility with Rack <= 1.1
  def size
    stat.size
  end unless File.method_defined?(:size)
end
