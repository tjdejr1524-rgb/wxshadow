# wxshadow — W^X Shadow Memory 无痕 Hook (KPM)

Adapted from the [shadow-memory hook technique](https://bbs.kanxue.com/thread-290304.htm)
for a rooted **OnePlus Android 16 / Linux 6.12.23** device (4KiB pages, va_bits=39,
3-level page tables). Runs as a [KernelPatch](https://github.com/bmax121/KernelPatch)
(KPM) module to perform **traceless** breakpoints/hooks via shadow physical pages:
a user PTE is redirected to a shadow copy of the page with a `BRK #0x7` injected at
the target address. On hit, the PTE is flipped back to the original page, the original
instruction is single-stepped, then the shadow is reinstalled. Readers of the target
process's memory see the original page — the breakpoint is invisible.

## Capabilities (all verified in closed-loop on device)

| Feature | Status | How verified |
|---|---|---|
| BRK breakpoint + register capture (x0–x30, sp, pc, pstate) | ✅ | `run_basic.sh` — x0=1..x7=8 captured |
| Thread info (comm, tid, tgid) | ✅ | `run_basic.sh` |
| Single-step original instruction | ✅ | step at 0x4006d8, acc=5a5a5a7e |
| Register modification (SET_REG) | ✅ | `run_regmod.sh` — x0=0x100 → acc=5a5a5b7d |
| Multi-breakpoint (same page) | ✅ | `run_multibp.sh` — 2 BPs, 5×5 hits |
| Shadow-page patch (custom instruction) | ✅ | `run_patch2.sh` |
| Read-hiding (`/proc/PID/mem` sees original) | ✅ | `run_readhide.sh` — reads ff0301d1 not BRK |
| GUP-hiding (`process_vm_readv`/ptrace sees original) | ✅ | `run_guphide.sh` |
| Fork protection (child does NOT inherit shadow) | ✅ | `run_fork.sh` — child status=0, no BRK |
| Remote-PID (hook another process) | ✅ | every test targets bptest's PID from client |
| Clean teardown + clean unload | ✅ | `exit_mmap` cleans pages, 5-phase unhook, rc=0 |
| Stability | ✅ | `run_repeat.sh` — 100/100 passed, 0 warnings |
| **No `find_vma`/`rwsem` kernel WARNING** | ✅ | 0 warnings in dmesg across all tests |

## Source files

- `wxshadow.c` — module init/exit, page lifecycle, teardown, prctl dispatch
- `wxshadow_pgtable.c` — lockless PTE walk (`get_user_pte`), BBM PTE writes,
  broadcast `tlbi vaale1is` TLB flush, shadow/original PTE builders
- `wxshadow_handlers.c` — BRK/step handlers, read/exec fault handlers,
  `exit_mmap` hook, GUP-hide (`follow_page_pte`), fork (`uprobe_dup_mmap`) hook
- `wxshadow_bp.c` — set_bp / set_reg / patch / release setup paths
- `wxshadow_scan.c` — runtime symbol + struct-offset scanning
- `wxshadow_internal.h` / `wxshadow.h` — internals & public headers
- `wxshadow_client.c` — userspace client (`prctl`-based)
- `CMakeLists.txt` — KPM + client build

## Test programs & scripts

- `bptest.c` — target with `--paused`/`--count`, `target_func` at 0x4006d4
- `forktest.c` — fork-protection verifier
- `gup_reader.c` — `process_vm_readv` reader for GUP-hide
- `run_*.sh` — closed-loop test scripts (basic, regmod, multibp, patch, readhide,
  guphide, fork, repeat)
- `build1..4.py` / `pull.py` / `upload.py` — VM build/deploy helpers
- `logger.sh` / `fulllog.sh` — on-device dmesg capture

## Build

Cross-compile on a Linux VM with `aarch64-linux-gnu-gcc` and the KPatch SDK:

```
cmake -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DKP_DIR=<KPatch-Next> ..
make wxshadow.kpm wxshadow_client
```

`build4.py` does a full clean build on the configured VM (192.168.229.128).

## Deploy to device

**Quirk:** directly overwriting `/data/local/tmp/<file>` via `adb push` silently
fails on this device (KernelSU redirect). Always push to `/sdcard/` first, then
`su -c "cp /sdcard/<file> /data/local/tmp/<file>"`, and verify with `md5sum`.

```
adb push wxshadow.kpm /sdcard/wxshadow.kpm
adb shell 'su -c "cp /sdcard/wxshadow.kpm /data/local/tmp/wxshadow.kpm"'
adb shell 'su -c "/data/adb/modules/KPatch-Next/bin/kpatch kpm load /data/local/tmp/wxshadow.kpm"'
```

## Usage

```
wxshadow_client -p <pid> -a <addr>                 # set breakpoint
wxshadow_client -p <pid> -a <addr> -r x0=<val>     # set bp with register mod
wxshadow_client -p <pid> -a <addr> --patch <hex>   # patch shadow page
wxshadow_client -p <pid> --release                  # release all shadows
```

## Key design notes (Linux 6.12 adaptation)

- **No `find_vma()` anywhere on runtime/exception paths.** 6.12 `find_vma` contains
  `WARN_ON_ONCE(rwsem_is_locked(&mm->mmap_lock))`; `mmap_read_lock` is `static inline`
  (unsafe by symbol) and `mm->mmap_lock` offset isn't provided by the KP framework.
  VMA bounds-checks are replaced by `get_user_pte()` + PFN validation
  (`wxshadow_validate_page_mapping`). THP/2MB-block targets are rejected with `-14`
  (`wxshadow_try_split_pmd_novma`); executable `.text` is normally 4KiB.
- **`page->mm` is the authoritative owner mm** (captured at set_bp from
  `get_task_mm`), never `vma_mm(vma)` (wrong on 6.12 `__randomize_layout`).
- **TLB flush = broadcast `tlbi vaale1is`** (all ASIDs, no VMA/ASID needed).
- **`g_wxshadow_initialized` must be set at end of `wxshadow_init()`** so that
  `wxshadow_exit()` runs the full 5-phase unhook — otherwise hooks are left
  dangling pointing at freed module code → reboot on next syscall.

## Known limitation

THP (2MiB block) targets cannot have breakpoints set (returns `-14`). Restoring
THP support requires reliably probing `mm->mmap_lock` offset to take
`down_read` + `find_vma` + `__split_huge_pmd`.
