/* forktest.c - parent calls target_func in a loop; on signal (USERSIG via file)
 * it forks; the child also calls target_func. With wxshadow bp armed in parent,
 * the child should NOT hit the bp (fork protection: shadow not inherited).
 * Build: aarch64-linux-gnu-gcc -static -O0 -o forktest forktest.c */
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <sys/wait.h>

__attribute__((noinline)) static unsigned long target_func(unsigned long a, unsigned long b,
                                                           unsigned long c, unsigned long d,
                                                           unsigned long e, unsigned long f,
                                                           unsigned long g, unsigned long h)
{
    return a + b + c + d + e + f + g + h + 0x5A5A5A5AUL;
}

int main(int argc, char **argv) {
    unsigned long i = 0, acc = 0;
    int paused = 0, dofork = 0;
    for (int a = 1; a < argc; a++) {
        if (!strcmp(argv[a], "--paused")) paused = 1;
        else if (!strcmp(argv[a], "--fork") && a+1 < argc) dofork = atoi(argv[++a]);
    }
    printf("forktest pid=%d\n", getpid());
    printf("target_func = %p\n", (void*)target_func);
    fflush(stdout);
    if (paused) {
        printf("forktest: PAUSED, waiting for /data/local/tmp/bptest_go\n");
        fflush(stdout);
        int w = 0;
        while (access("/data/local/tmp/bptest_go", F_OK) != 0) {
            usleep(100000); if (++w > 300) break;
        }
        unlink("/data/local/tmp/bptest_go");
    }
    /* Run a few iters in parent */
    for (i = 1; i <= 3; i++) {
        acc = target_func(i, i*2, i*3, i*4, i*5, i*6, i*7, i*8);
        usleep(50000);
    }
    printf("parent: did 3 iters, last acc=%lx, now forking\n", acc);
    fflush(stdout);

    if (dofork) {
        pid_t cpid = fork();
        if (cpid == 0) {
            /* child: call target_func N times. Should NOT hit BRK. */
            unsigned long ci, ca = 0;
            for (ci = 1; ci <= (unsigned long)dofork; ci++) {
                ca = target_func(ci, ci*2, ci*3, ci*4, ci*5, ci*6, ci*7, ci*8);
                usleep(50000);
            }
            printf("child pid=%d: did %d iters, last acc=%lx (expected %lx)\n",
                   getpid(), dofork, ca,
                   (unsigned long)dofork + (unsigned long)dofork*2 + (unsigned long)dofork*3 +
                   (unsigned long)dofork*4 + (unsigned long)dofork*5 + (unsigned long)dofork*6 +
                   (unsigned long)dofork*7 + (unsigned long)dofork*8 + 0x5A5A5A5AUL);
            fflush(stdout);
            _exit(0);
        } else if (cpid > 0) {
            int status; waitpid(cpid, &status, 0);
            printf("parent: child exited status=%d (0=clean, no BRK)\n", status);
            fflush(stdout);
        } else { perror("fork"); }
    }
    printf("forktest: done acc=%lx\n", acc);
    fflush(stdout);
    return 0;
}
