require "mkmf"
require "ruby_core_source"

if RUBY_VERSION < "1.9"
  STDERR.print("Ruby version is too old\n")
  exit(1)
end

hdrs = proc {
  have_struct_member("rb_method_entry_t", "body", "method.h")
  have_header("vm_core.h") and have_header("iseq.h") and have_header("insns.inc") and 
  have_header("insns_info.inc") and have_header("eval_intern.h")
}

if RUBY_VERSION == '1.9.1'
  $CFLAGS << ' -DRUBY_VERSION_1_9_1'
end

if RUBY_REVISION >= 26959 # rb_iseq_compile_with_option was added an argument filepath
  $CFLAGS << ' -DRB_ISEQ_COMPILE_6ARGS'
end

dir_config("ruby")
if !Ruby_core_source::create_makefile_with_core(hdrs, "ruby_debug")
  STDERR.print("Makefile creation failed\n")
  STDERR.print("*************************************************************\n\n")
  STDERR.print("  NOTE: For Ruby 1.9 installation instructions, please see:\n\n")
  STDERR.print("     http://wiki.github.com/mark-moseley/ruby-debug\n\n")
  STDERR.print("*************************************************************\n\n")
  exit(1)
end
