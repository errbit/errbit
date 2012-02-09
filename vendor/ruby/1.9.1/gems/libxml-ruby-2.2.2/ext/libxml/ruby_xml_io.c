/* Please see the LICENSE file for copyright and distribution information */

#include "ruby_libxml.h"

static ID READ_METHOD;

/* This method is called by libxml when it wants to read
 more data from a stream. We go with the duck typing
 solution to support StringIO objects. */
int rxml_read_callback(void *context, char *buffer, int len)
{
  VALUE io = (VALUE) context;
  VALUE string = rb_funcall(io, READ_METHOD, 1, INT2NUM(len));
  int size;

  if (string == Qnil)
    return 0;

  size = RSTRING_LEN(string);
  memcpy(buffer, StringValuePtr(string), size);

  return size;
}

void rxml_init_io(void)
{
  READ_METHOD = rb_intern("read");
}
