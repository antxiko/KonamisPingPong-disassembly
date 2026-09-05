# Getting started

The repository ships the listing already generated, but what really matters is
that it can be **rebuilt from the cartridge** and that the result is the ROM
byte for byte. That is what makes the notes believable.

## What you need

- **Python 3** (that is all: not one dependency)
- **pasmo**, the Z80 assembler, for the reassembly check
- **make**
- For the checks against the machine, **openMSX**

## The cartridge

It does not travel with the repository. Put it in the root as `pingpong.rom`,
exactly 16,384 bytes:

    8e0f57b2c52e85505505c1d4bb4643eb7311213676f0ecfe21dd06571fc0bbd5

To check it is the same one:

    make comprueba

## Rebuilding everything

    make

That chains the four things that matter:

| step | what it does |
|---|---|
| `make listado` | traces the flow from the entry points and writes `src/pingpong.asm` |
| `make verify` | reassembles with pasmo and compares the sha256 against the cartridge |
| `make sanity` | what reassembly CANNOT catch (see below) |
| `make test` | the 36 tests |

## Why `make verify` is not enough

Reassembly proves the **bytes** are the same, not that what we say about them
is true. If a data table were read as code, the binary would still come out
identical: the only thing that would change is the lie in the listing.

So `make sanity` checks three more things:

- that no range declared as data shows up traced as code
- that no entry point falls inside a data range
- that **not one byte of the cartridge is left unassigned**: code reached plus
  data declared must add up to 16,384

## The numbers

    make densidad

It gives the two that get published: how many instructions carry a comment,
and whether any routine is left below 10 %.

## The pictures

    make imagenes

It draws the screens **from the bytes of the ROM**, running in Python the same
steps the Z80 runs. There is not one screen capture in this repository.

And to check them against the real machine:

    "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
        -cart pingpong.rom -script tools/omsx_vram.tcl
    python3 tools/coteja_vram.py pingpong.rom work/omsx/vram_01.bin logotipo

That dumps the emulator's 16 KB of VRAM at several moments and compares them
byte for byte against what `tools/graficos.py` builds.

## The files written by hand

Only three, and all three carry the reasoning behind every decision:

- `src/pingpong.entries` — the entry points the tracer cannot work out on its
  own, each with its justification
- `src/pingpong.nocode` — the ranges that are NOT code
- `src/pingpong.notes` — the names, the comments and the data ranges

Everything else comes out of those.
