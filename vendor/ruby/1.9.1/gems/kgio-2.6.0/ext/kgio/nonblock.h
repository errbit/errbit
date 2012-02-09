#include <ruby.h>
#include <unistd.h>
#include <fcntl.h>
static void set_nonblocking(int fd)
{
	int flags = fcntl(fd, F_GETFL);

	if (flags == -1)
		rb_sys_fail("fcntl(F_GETFL)");
	if ((flags & O_NONBLOCK) == O_NONBLOCK)
		return;
	flags = fcntl(fd, F_SETFL, flags | O_NONBLOCK);
	if (flags == -1)
		rb_sys_fail("fcntl(F_SETFL)");
}
