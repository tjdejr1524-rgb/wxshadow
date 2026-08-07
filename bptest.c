/*
 * bptest.c - minimal native test for wxshadow breakpoint.
 * Loops forever calling target_func with known args so we can
 * verify register capture (x0-x7) and thread info at the hook point.
 *
 * Build: aarch64-linux-gnu-gcc -static -O0 -o bptest bptest.c
 */
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* Target function: called with recognizable values so we can verify
 * the captured registers at the breakpoint. Not inlined, stable address. */
__attribute__((noinline)) static unsigned long target_func(unsigned long a, unsigned long b,
                                                           unsigned long c, unsigned long d,
                                                           unsigned long e, unsigned long f,
                                                           unsigned long g, unsigned long h)
{
    /* Simple arithmetic that returns a recognizable result */
    return a + b + c + d + e + f + g + h + 0x5A5A5A5AUL;
}

int main(int argc, char **argv)
{
    unsigned long i = 0;
    unsigned long acc = 0;
    unsigned long count = 0;      /* 0 = infinite */
    int paused = 0;

    /* --paused: print PID/address and block on stdin until a line arrives,
     * so the controller can arm the breakpoint before target_func runs.
     * --count N: run target_func exactly N times then exit (default inf). */
    for (int a = 1; a < argc; a++) {
        if (strcmp(argv[a], "--paused") == 0)
            paused = 1;
        else if (strcmp(argv[a], "--count") == 0 && a + 1 < argc)
            count = strtoul(argv[++a], NULL, 0);
    }

    printf("bptest pid=%d\n", getpid());
    printf("target_func = %p\n", (void *)target_func);
    fflush(stdout);

    if (paused) {
        /* Wait for a trigger file to appear (controller creates it after
         * arming the breakpoint). More robust than stdin over adb shell. */
        printf("bptest: PAUSED, waiting for /data/local/tmp/bptest_go\n");
        fflush(stdout);
        int waited = 0;
        while (access("/data/local/tmp/bptest_go", F_OK) != 0) {
            usleep(100000);
            if (++waited > 300) { /* 30s timeout */
                printf("bptest: go-file timeout, starting anyway\n");
                fflush(stdout);
                break;
            }
        }
        unlink("/data/local/tmp/bptest_go");
    }

    for (;;) {
        i++;
        acc = target_func(i, i * 2, i * 3, i * 4, i * 5, i * 6, i * 7, i * 8);
        if (acc == 0)   /* never true, keeps compiler honest */
            printf("unreachable\n");
        if (count) {
            if (i >= count)
                break;
        } else if ((i % 1000000) == 0) {
            printf("i=%lu acc=%lx\n", i, acc);
            fflush(stdout);
        }
        usleep(1000);  /* 1ms per iteration */
    }

    printf("bptest: done i=%lu acc=%lx\n", i, acc);
    fflush(stdout);
    return 0;
}
