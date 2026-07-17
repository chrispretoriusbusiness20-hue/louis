# OpenART on Linux with GCC — complete port

Working port of [nxp-mcuxpresso/OpenART](https://github.com/nxp-mcuxpresso/OpenART)
(imxrt1062-nxp-evk BSP) to Linux + GNU Arm GCC, replacing the officially
supported Windows + Keil MDK flow.

## Status: BUILDS ✅

`scons` now produces `rtthread.elf` / `rtthread.bin` (≈2.4 MB XIP image):

```
   text    data      bss
2457620    8792 23154636   rtthread.elf
```

RT-Thread kernel, board support, drivers, MicroPython, OpenMV, LVGL, and the
prebuilt TFLite-Micro/NNCU libraries all link. The large BSS is the SDRAM
framebuffer/heap layout. **Not yet validated on hardware** — the image boots
the same XIP boot-header path Keil used, but flash it expecting to debug.

## Toolchain recipe (Ubuntu 24.04)

Version choices matter — newer components break on this vintage codebase:

| Component | Version | Why |
|---|---|---|
| SCons | 4.4.0 (`pip install scons==4.4.0`) | SCons ≥ 4.5 makes `CPPDEFINES` a deque; `tools/building.py` crashes concatenating it with a list. |
| ARM GCC | 9-2019-q4 (Ubuntu 20.04 `gcc-arm-none-eabi` deb) | GCC 13's newlib 4.3 collides with RT-Thread's bundled `libc_signal.h`. |
| newlib | 3.3.0 (`libnewlib-arm-none-eabi` + `libnewlib-dev` focal debs) | Matches GCC 9; still needs the `cconfig.h` below. |
| libisl22 | 0.22.1 focal deb | Dependency of the GCC 9 deb on 24.04. |

The focal debs install cleanly on 24.04 with `dpkg -i` after removing the
24.04 `gcc-arm-none-eabi`/newlib packages.

## Build

```sh
git apply openart-gcc-fixes.patch          # in the OpenART checkout
# write cconfig.h (below) into bsp/imxrt/imxrt1062-nxp-evk/
# convert the Keil libs once:
cd bsp/imxrt/components/openmv-nxp
cp nncu/nncie_m4_m7_m33_sp_cmsisnn.lib nncu/libnncie_m4_m7_m33_sp_cmsisnn.a
cp libtf/cortex-m7/libtf.lib libtf/cortex-m7/libtf.a
cp libtf/cortex-m7/libtf_person_detect_model_data.lib libtf/cortex-m7/libtf_person_detect_model_data.a
cd ../../imxrt1062-nxp-evk
RTT_EXEC_PATH=/usr/bin scons -j4
```

The Keil `.lib` archives contain armclang EABI5 ELF objects — GNU ld links
them directly once they have `lib*.a` names.

### cconfig.h

RT-Thread's GCC autodetection scans newlib relative to `EXEC_PATH`, which
doesn't match Ubuntu's layout, so it generates an empty file. Overwrite
`bsp/imxrt/imxrt1062-nxp-evk/cconfig.h` with:

```c
#ifndef CCONFIG_H__
#define CCONFIG_H__
#define HAVE_NEWLIB_H 1
#define LIBC_VERSION "newlib 3.3.0"
#define HAVE_SYS_SIGNAL_H 1
#define HAVE_SYS_SELECT_H 1
#define HAVE_PTHREAD_H 1
#define HAVE_FDSET 1
#define HAVE_SIGACTION 1
#define HAVE_SIGEVENT 1
#define HAVE_SIGINFO 1
#define HAVE_SIGVAL 1
#define STDC "1989"
#endif
```

## What the patch contains (12 files)

**Compile fixes**
1. `board/SConscript` — defines jammed into one comma-separated string
   (armcc tolerated it, GCC errors); also guards the Windows-only
   `make-pins.py` regeneration that clobbers the checked-in pins file with an
   empty one on Linux.
2. `py/nlr.h` — `#undef __arm__` before `<setjmp.h>` blanked newlib's arch
   detection so `jmp_buf` never existed; include setjmp first.
3. `extmod/irqmap.c` — `static int index[4]` vs libc `index()`.
4. `mpy_main.c` — duplicate `Image$$MPY_HEAP_START$$Base` extern with
   conflicting type.
5. `omv_main.c`, `omv/fb_alloc.c` — extend the Keil `#if` branches to
   `__GNUC__` (the GCC branches were empty stubs upstream).
6. `omv/img/fmath.c` — `fast_fabsf` was C99 `inline` without an extern
   definition; de-inlined.
7. `libraries/sensors/drv_camera_int.c` — `RAM_CODE` macro was never defined
   anywhere; defined as `section(".ram_code")`.

**The GCC link layer (the part Keil provided before)**
8. `board/linker_scripts/link.lds` — NEW: full GNU ld script merging the NXP
   SDK skeleton with OpenART's Keil scatter layout. Provides every
   `Image$$...$$`/`Load$$...$$` symbol the sources consume, the RT-Thread
   init/FinSH tables, and the memory map: XIP flash boot header → ITCM
   (RAM code incl. flash drivers + LVGL fast code) → DTCM (fb_alloc overlay
   120K + 8K MSP stack) → OCRAM 768K (data/bss/LVGL/weight-cache) → SDRAM
   (RTT heap, MPY thread stack + 4M heap, 6M sensor buffer, 10M OMV
   framebuffer, 48K JPEG buffer, 1M LCD framebuffer) → 2M non-cacheable
   window (USB DMA buffers). Uses the fused-default FlexRAM banking
   (128K/128K/256K) — the Keil scatter assumed more DTCM than the chip
   default provides.
9. `board/gcc_compat.c` — NEW: shims for the armclang-built ML libraries:
   `__hardfp_*` math, `__aeabi_assert`/`__aeabi_errno_addr`/`__stderr`,
   `operator new/delete` on the RT-Thread heap, and no-op libc++
   `ios_base::Init` stubs.
10. `board/board.c` — run C++ static constructors via `__libc_init_array()`
    under GCC (Keil did it via `$Super$$__cpp_initialize__aeabi_` patching).
11. `rtconfig.py` — assemble startup with `-D__STARTUP_CLEAR_BSS
    -D__STARTUP_INITIALIZE_RAMFUNCTION -D__STARTUP_INITIALIZE_NONCACHEDATA`
    (otherwise BSS is never cleared with `-nostartfiles`).

## Known caveats

- armclang libs use 2-byte `wchar_t` (link warning; wchar is unused on target).
- `__stderr` writes from the armclang libs are dropped (inert stub).
- The Keil build placed `gc.o`/CMSIS-NN hot code in ITCM for speed; the GCC
  script currently only pins `.ram_code`, LVGL fast code, and the flash
  drivers there. Perf tuning headroom remains (~100K ITCM free).
- Runtime validation (boot, MicroPython REPL, camera, TFLite inference)
  requires a physical MIMXRT1060-EVK/OpenART board.
