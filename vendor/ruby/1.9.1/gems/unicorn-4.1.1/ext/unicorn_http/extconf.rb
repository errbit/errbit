# -*- encoding: binary -*-
require 'mkmf'

have_macro("SIZEOF_OFF_T", "ruby.h") or check_sizeof("off_t", "sys/types.h")
have_macro("SIZEOF_SIZE_T", "ruby.h") or check_sizeof("size_t", "sys/types.h")
have_macro("SIZEOF_LONG", "ruby.h") or check_sizeof("long", "sys/types.h")
have_func("rb_str_set_len", "ruby.h")
have_func("gmtime_r", "time.h")

create_makefile("unicorn_http")
