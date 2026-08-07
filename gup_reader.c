/* gup_reader.c - read 4 bytes at an addr in another PID via process_vm_readv.
 * Build: aarch64-linux-gnu-gcc -static -o gup_reader gup_reader.c */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/uio.h>

int main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "usage: %s <pid> <hex_addr>\n", argv[0]); return 1; }
    pid_t pid = atoi(argv[1]);
    unsigned long addr = strtoul(argv[2], NULL, 16);
    unsigned char buf[4] = {0};
    struct iovec liov = { buf, 4 };
    struct iovec riov  = { (void*)addr, 4 };
    ssize_t n = process_vm_readv(pid, &liov, 1, &riov, 1, 0);
    if (n != 4) { perror("process_vm_readv"); return 2; }
    printf("process_vm_readv read 4 bytes at 0x%lx: %02x %02x %02x %02x\n",
           addr, buf[0], buf[1], buf[2], buf[3]);
    return 0;
}
