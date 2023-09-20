// on linux >= 6.2 ensure sysctl dev.tty.legacy_tiocsti=1

#define _GNU_SOURCE
#include <sys/ioctl.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <errno.h>
#include <string.h>

static int ioctl64(int fd, unsigned long nr, void *arg) {
	errno = 0;
	return syscall(__NR_ioctl, fd, nr, arg);
}

int main(void) {
	char* pushback = "echo hi\n";

	for(int i = 0; i < strlen(pushback); ++i){
		ioctl64(0, TIOCSTI, &pushback[i]);
	}
}
