#include <ruby.h>
#ifdef HAVE_RUBY_IO_H
#  include <ruby/io.h>
#else
#  include <rubyio.h>
#endif

#ifdef HAVE_RUBY_ST_H
#  include <ruby/st.h>
#else
#  include <st.h>
#endif

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "set_file_path.h"

static ID id_for_fd, id_to_path, id_path;
static st_table *errno2sym;

struct open_args {
	const char *pathname;
	int flags;
	mode_t mode;
};

static VALUE nogvl_open(void *ptr)
{
	struct open_args *o = ptr;

	return (VALUE)open(o->pathname, o->flags, o->mode);
}

#ifndef HAVE_RB_THREAD_BLOCKING_REGION
#  define RUBY_UBF_IO ((void *)(-1))
#  include "rubysig.h"
typedef void rb_unblock_function_t(void *);
typedef VALUE rb_blocking_function_t(void *);
static VALUE rb_thread_blocking_region(
	rb_blocking_function_t *fn, void *data1,
	rb_unblock_function_t *ubf, void *data2)
{
	VALUE rv;

	TRAP_BEG; /* for FIFO */
	rv = fn(data1);
	TRAP_END;

	return rv;
}
#endif /* ! HAVE_RB_THREAD_BLOCKING_REGION */

/*
 * call-seq:
 *
 *	Kgio::File.tryopen(filename, [, mode [, perm]])	-> Kgio::File or Symbol
 *
 * Returns a Kgio::File object on a successful open.  +filename+ is a
 * path to any file on the filesystem.  If specified, +mode+ is a bitmask
 * of flags (see IO.sysopen) and +perm+ should be an octal number.
 *
 * This does not raise errors for most failures, but installs returns a
 * Ruby symbol for the constant in the Errno::* namespace.
 *
 * Common error symbols are:
 *
 * - :ENOENT
 * - :EACCES
 *
 * See your open(2) manpage for more information on open(2) errors.
 */
static VALUE s_tryopen(int argc, VALUE *argv, VALUE klass)
{
	int fd;
	VALUE pathname, flags, mode;
	struct open_args o;
	int retried = 0;
	VALUE rv;

	rb_scan_args(argc, argv, "12", &pathname, &flags, &mode);
	if (rb_respond_to(pathname, id_to_path))
		pathname = rb_funcall(pathname, id_to_path, 0);
	o.pathname = StringValueCStr(pathname);

	switch (TYPE(flags)) {
	case T_NIL: o.flags = O_RDONLY; break;
	case T_FIXNUM: o.flags = FIX2INT(flags); break;
	case T_BIGNUM: o.flags = NUM2INT(flags); break;
	default: rb_raise(rb_eArgError, "flags must be an Integer");
	}
	switch (TYPE(mode)) {
	case T_NIL: o.mode = 0666; break;
	case T_FIXNUM: o.mode = FIX2INT(mode); break;
	case T_BIGNUM: o.mode = NUM2INT(mode); break;
	default: rb_raise(rb_eArgError, "mode must be an Integer");
	}

retry:
	fd = (int)rb_thread_blocking_region(nogvl_open, &o, RUBY_UBF_IO, 0);
	if (fd == -1) {
		if (errno == EMFILE || errno == ENFILE || errno == ENOMEM) {
			rb_gc();
			if (retried)
				rb_sys_fail(o.pathname);
			retried = 1;
			goto retry;
		}
		if (fd == -1) {
			int saved_errno = errno;

			if (!st_lookup(errno2sym, (st_data_t)errno, &rv)) {
				errno = saved_errno;
				rb_sys_fail(o.pathname);
			}
			return rv;
		}
	}
	rv = rb_funcall(klass, id_for_fd, 1, INT2FIX(fd));
	set_file_path(rv, pathname);
	return rv;
}

void init_kgio_tryopen(void)
{
	VALUE mKgio = rb_define_module("Kgio");
	VALUE mPipeMethods = rb_const_get(mKgio, rb_intern("PipeMethods"));
	VALUE cFile;
	VALUE tmp;
	VALUE *ptr;
	long len;

	id_path = rb_intern("path");
	id_for_fd = rb_intern("for_fd");
	id_to_path = rb_intern("to_path");

	/*
	 * Document-class: Kgio::File
	 *
	 * This subclass of the core File class adds the "tryopen" singleton
	 * method for opening files.  A single "tryopen" and check for the
	 * return value may be used to avoid unnecessary stat(2) syscalls
	 * or File.open exceptions when checking for the existence of a file
	 * and opening it.
	 */
	cFile = rb_define_class_under(mKgio, "File", rb_cFile);
	rb_define_singleton_method(cFile, "tryopen", s_tryopen, -1);
	rb_include_module(cFile, mPipeMethods);

	if (!rb_funcall(cFile, rb_intern("method_defined?"), 1,
	                ID2SYM(id_to_path)))
		rb_define_alias(cFile, "to_path", "path");

	errno2sym = st_init_numtable();
	tmp = rb_funcall(rb_mErrno, rb_intern("constants"), 0);
	ptr = RARRAY_PTR(tmp);
	len = RARRAY_LEN(tmp);
	for (; --len >= 0; ptr++) {
		VALUE error;
		ID const_id;

		switch (TYPE(*ptr)) {
		case T_SYMBOL: const_id = SYM2ID(*ptr); break;
		case T_STRING: const_id = rb_intern(RSTRING_PTR(*ptr)); break;
		default: rb_bug("constant not a symbol or string");
		}

		error = rb_const_get(rb_mErrno, const_id);
		if ((TYPE(error) != T_CLASS) ||
		    !rb_const_defined(error, rb_intern("Errno")))
			continue;

		error = rb_const_get(error, rb_intern("Errno"));
		switch (TYPE(error)) {
		case T_FIXNUM:
		case T_BIGNUM:
			st_insert(errno2sym, (st_data_t)NUM2INT(error),
			          ID2SYM(const_id));
		}
	}
}
