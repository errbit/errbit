require 'mkmf'

dir_config('atomic_ops')
have_func('mmap', 'sys/mman.h') or abort 'mmap() not found'
have_func('munmap', 'sys/mman.h') or abort 'munmap() not found'

$CPPFLAGS += " -D_GNU_SOURCE "
have_func('mremap', 'sys/mman.h')

$CPPFLAGS += " -D_BSD_SOURCE "
have_func("getpagesize", "unistd.h")
have_func('rb_thread_blocking_region')
have_func('rb_thread_io_blocking_region')

checking_for "GCC 4+ atomic builtins" do
  src = <<SRC
int main(int argc, char * const argv[]) {
        volatile unsigned long i = 0;
        __sync_add_and_fetch(&i, argc);
        __sync_sub_and_fetch(&i, argc);
        return 0;
}
SRC

  if try_run(src)
    # some systems target GCC for i386 and don't get the atomic builtins
    # when building shared objects
    arch = `#{CONFIG['CC']} -dumpmachine`.split(/-/)[0]
    if arch == "i386" && $CFLAGS !~ /\b-march=/
      $CFLAGS += " -march=i486 "
    end

    $defs.push(format("-DHAVE_GCC_ATOMIC_BUILTINS"))
    true
  else
    false
  end
end or have_header('atomic_ops.h') or abort <<-SRC

libatomic_ops is required if GCC 4+ is not used.
See http://www.hpl.hp.com/research/linux/atomic_ops/

Users of Debian-based distros may run:

  apt-get install libatomic-ops-dev
SRC
create_makefile('raindrops_ext')
