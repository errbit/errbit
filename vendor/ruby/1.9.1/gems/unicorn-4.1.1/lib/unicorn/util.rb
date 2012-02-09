# -*- encoding: binary -*-

module Unicorn::Util

# :stopdoc:
  def self.is_log?(fp)
    append_flags = File::WRONLY | File::APPEND

    ! fp.closed? &&
      fp.sync &&
      (fp.fcntl(Fcntl::F_GETFL) & append_flags) == append_flags
    rescue IOError, Errno::EBADF
      false
  end

  def self.chown_logs(uid, gid)
    ObjectSpace.each_object(File) do |fp|
      fp.chown(uid, gid) if is_log?(fp)
    end
  end
# :startdoc:

  # This reopens ALL logfiles in the process that have been rotated
  # using logrotate(8) (without copytruncate) or similar tools.
  # A +File+ object is considered for reopening if it is:
  #   1) opened with the O_APPEND and O_WRONLY flags
  #   2) the current open file handle does not match its original open path
  #   3) unbuffered (as far as userspace buffering goes, not O_SYNC)
  # Returns the number of files reopened
  #
  # In Unicorn 3.5.x and earlier, files must be opened with an absolute
  # path to be considered a log file.
  def self.reopen_logs
    to_reopen = []
    nr = 0
    ObjectSpace.each_object(File) { |fp| is_log?(fp) and to_reopen << fp }

    to_reopen.each do |fp|
      orig_st = begin
        fp.stat
      rescue IOError, Errno::EBADF
        next
      end

      begin
        b = File.stat(fp.path)
        next if orig_st.ino == b.ino && orig_st.dev == b.dev
      rescue Errno::ENOENT
      end

      begin
        File.open(fp.path, 'a') { |tmpfp| fp.reopen(tmpfp) }
        fp.sync = true
        new_st = fp.stat

        # this should only happen in the master:
        if orig_st.uid != new_st.uid || orig_st.gid != new_st.gid
          fp.chown(orig_st.uid, orig_st.gid)
        end

        nr += 1
      rescue IOError, Errno::EBADF
        # not much we can do...
      end
    end
    nr
  end
end
