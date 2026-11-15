# wxshadow용 Makefile (KernelPatch 표준 KPM 빌드 방식)
TARGET_COMPILE := aarch64-linux-gnu-
KP_DIR ?= $(CURDIR)/../KernelPatch

CC := $(TARGET_COMPILE)gcc
LD := $(TARGET_COMPILE)ld

# KPM 컴파일 필수 플래그: relocatable ELF 생성을 위한 -r
# KernelPatch 헤더 경로 (DeepWiki 문서 기준)
INCLUDE_DIRS := \
    include \
    patch/include \
    linux/include \
    linux/arch/arm64/include \
    linux/tools/arch/arm64/include

CFLAGS := -r -fno-pic -mgeneral-regs-only -O2 -nostdinc \
          -I$(KP_DIR)/kernel/include \
          -I$(KP_DIR)/kernel/patch/include \
          -I$(KP_DIR)/kernel/include/uapi

# 소스 파일 목록 (wxshadow 저장소 구조에 맞게 수정 필요)
# 예: wxshadow_pgtable.c, wxshadow_handlers.c, wxshadow.c, wxshadow_bp.c 등
SRCS := $(wildcard *.c)

wxshadow.kpm: $(SRCS)
	$(CC) $(CFLAGS) -o $@ $^

wxshadow_client: wxshadow_client.c
	$(CC) -O2 -o $@ $<

.PHONY: clean
clean:
	rm -f wxshadow.kpm wxshadow_client
