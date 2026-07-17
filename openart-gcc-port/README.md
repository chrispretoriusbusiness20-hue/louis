# OpenART on Linux with GCC — setup notes and fixes

Working notes from getting [nxp-mcuxpresso/OpenART](https://github.com/nxp-mcuxpresso/OpenART)
building on Linux with the GNU Arm toolchain, instead of the officially
supported Windows + Keil MDK flow.

## Status

- RT-Thread kernel, board support, drivers, and the MicroPython core **compile**
  with the recipe below plus `openart-gcc-fixes.patch`.
- Final linking is **not yet possible with GCC**: the i.MX RT1062 BSP ships only
  Keil scatter files (`board/linker_scripts/*.sct`) — the `link.lds` referenced
  by `rtconfig.py` does not exist in the repo — and nine source files use
  Keil-only `Image$$...$$` linker symbols (OpenMV framebuffer/heap setup,
  MicroPython heap, model overlays). Completing the port means authoring the
  full memory map (ITCM/DTCM/OCRAM/SDRAM, XIP boot header, overlay sections)
  as a GNU ld script and porting those symbol usages.
- For real hardware work today, use the supported path: Windows + Keil MDK
  ≥ 5.33, `scons --target=mdk5 -s` in the BSP folder, build and flash in Keil.

## Toolchain recipe (Ubuntu 24.04)

Version choices matter — newer components break on this vintage codebase:

| Component | Version | Why this version |
|---|---|---|
| SCons | 4.4.0 (`pip install scons==4.4.0`) | SCons ≥ 4.5 makes `CPPDEFINES` a deque; OpenART's `tools/building.py` concatenates it with a list and crashes. |
| ARM GCC | 9-2019-q4 (Ubuntu 20.04 `gcc-arm-none-eabi` deb) | GCC 13 ships newlib 4.3, whose unconditional `sigval`/`sigevent`/`siginfo_t` definitions collide with RT-Thread's bundled `libc_signal.h`. |
| newlib | 3.3.0 (`libnewlib-arm-none-eabi` + `libnewlib-dev` focal debs) | Matches GCC 9 era; still needs the `cconfig.h` below. |
| libisl22 | 0.22.1 focal deb | Runtime dependency of the GCC 9 deb on 24.04. |

The focal debs install cleanly on 24.04 with `dpkg -i` after removing the
24.04 `gcc-arm-none-eabi`/newlib packages.

## cconfig.h

RT-Thread's GCC autodetection (`tools/gcc.py`) scans newlib headers relative to
the toolchain `EXEC_PATH`, which doesn't match Ubuntu's split layout
(`/usr/include/newlib`), so it generates an empty `cconfig.h` and the signal
types collide anyway. Overwrite `bsp/imxrt/imxrt1062-nxp-evk/cconfig.h` with:

```c
#ifndef CCONFIG_H__
#define CCONFIG_H__
/* compiler configure file for RT-Thread in GCC */
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

(The build only regenerates it when missing, so a hand-written one sticks.)

## Source fixes

Apply `openart-gcc-fixes.patch` from this directory (`git apply`) on top of
OpenART `master`. What it fixes:

1. **`bsp/imxrt/imxrt1062-nxp-evk/board/SConscript`** — six preprocessor
   defines were jammed into one comma-separated string
   (`'XIP_BOOT_HEADER_ENABLE=1,ARM_MATH_CM7,...'`); armcc tolerated it, GCC
   errors with `token "=" is not valid in preprocessor expressions`.
2. **`components/micropython-nxp/py/nlr.h`** — the port `#undef`s
   `__arm__`/`__thumb__` (to force setjmp-based NLR) *before* including
   `<setjmp.h>`; with those gone, newlib's `machine/setjmp.h` can't detect the
   architecture and never typedefs `jmp_buf`. Fix: include `<setjmp.h>` before
   the `#undef`s.
3. **`components/micropython-nxp/extmod/irqmap.c`** — a file-scope
   `static int index[4]` collides with libc's BSD `index()`; renamed.
4. **`components/micropython-nxp/port/mpy_main.c`** — duplicate `extern`
   declaration of `Image$$MPY_HEAP_START$$Base` with a conflicting type
   (`uint32_t` is `unsigned long` on newlib ARM; the earlier declaration says
   `unsigned int`).

## Build

```sh
cd bsp/imxrt/imxrt1062-nxp-evk
RTT_EXEC_PATH=/usr/bin scons -j4
```

Compilation currently stops in `components/openmv-nxp/omv_main.c` at
`_heap_start` / `_thread_stack_start` — linker-provided symbols the GCC code
path expects but no linker script defines. That's the start of the remaining
porting work described under **Status**.
