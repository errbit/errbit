require "mkmf"
require "ruby_core_source"

if RUBY_VERSION >= "1.8"
  if RUBY_RELEASE_DATE < "2005-03-22"
    STDERR.print("Ruby version is too old\n")
    exit(1)
  end
else
  STDERR.print("Ruby version is too old\n")
  exit(1)
end

hdrs = proc {
  have_header("vm_core.h") and have_header("version.h")
}

dir_config("ruby")
if !Ruby_core_source::create_makefile_with_core(hdrs, "trace_nums19")
  STDERR.print("Makefile creation failed\n")
  STDERR.print("*************************************************************\n\n")
  STDERR.print("  NOTE: For Ruby 1.9 installation instructions, please see:\n\n")
  STDERR.print("     http://wiki.github.com/mark-moseley/ruby-debug\n\n")
  STDERR.print("*************************************************************\n\n")
  exit(1)
end  
