TARGET_COMPILE := aarch64-linux-gnu-
KP_DIR ?= $(CURDIR)/KernelPatch

CC := $(TARGET_COMPILE)gcc

# KPM 커널 모듈 소스만 (stdio.h 필요 없는 것들)
KPM_SRCS := wxshadow.c wxshadow_bp.c wxshadow_handlers.c wxshadow_pgtable.c wxshadow_scan.c

# 사용자공간 소스 (별도 빌드)
USER_SRCS := wxshadow_client.c bptest.c forktest.c gup_reader.c

KPM_CFLAGS := -r -fno-pic -mgeneral-regs-only -O2 -nostdinc -nostdlib \
              -I$(KP_DIR)/kernel/include \
              -I$(KP_DIR)/kernel/patch/include \
              -I$(KP_DIR)/kernel/include/uapi

USER_CFLAGS := -O2

all: wxshadow.kpm

wxshadow.kpm: $(KPM_SRCS)
	$(CC) $(KPM_CFLAGS) -o $@ $^

# 사용자공간은 별도 타겟 (필요할 때만)
client: $(USER_SRCS)
	$(CC) $(USER_CFLAGS) -o wxshadow_client wxshadow_client.c
	$(CC) $(USER_CFLAGS) -o bptest bptest.c
	$(CC) $(USER_CFLAGS) -o forktest forktest.c
	$(CC) $(USER_CFLAGS) -o gup_reader gup_reader.c

.PHONY: all client clean
clean:
	rm -f wxshadow.kpm wxshadow_client bptest forktest gup_reader
