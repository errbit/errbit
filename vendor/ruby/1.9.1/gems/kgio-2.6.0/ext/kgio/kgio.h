#ifndef KGIO_H
#define KGIO_H

#include <ruby.h>
#ifdef HAVE_RUBY_IO_H
#  include <ruby/io.h>
#else
#  include <rubyio.h>
#endif
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <assert.h>
#include <netdb.h>

#include "ancient_ruby.h"

struct io_args {
	VALUE io;
	VALUE buf;
	char *ptr;
	long len;
	int fd;
};

void init_kgio_wait(void);
void init_kgio_read_write(void);
void init_kgio_accept(void);
void init_kgio_connect(void);
void init_kgio_autopush(void);
void init_kgio_poll(void);
void init_kgio_tryopen(void);

void kgio_autopush_accept(VALUE, VALUE);
void kgio_autopush_recv(VALUE);
void kgio_autopush_send(VALUE);

VALUE kgio_call_wait_writable(VALUE io);
VALUE kgio_call_wait_readable(VALUE io);
#if defined(HAVE_RB_THREAD_BLOCKING_REGION) && defined(HAVE_POLL)
#  define USE_KGIO_POLL
#endif /* USE_KGIO_POLL */

#endif /* KGIO_H */
