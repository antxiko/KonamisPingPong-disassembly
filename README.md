# Konami's Ping Pong (Konami, 1985) — a commented disassembly

A complete, commented disassembly of the MSX1 cartridge **Konami's Ping Pong**
(Konami, catalogue number **RC-731**, 16 KB), reproducible byte for byte.

**Web: <https://antxiko.github.io/KonamisPingPong-disassembly/>** · [En castellano](README.es.md)

|  |  |
|---|---|
| Of the binary explained | **100%** — 0 bytes unaccounted for, of 16,384 |
| Reassembles | **byte for byte**, to the same sha256 |
| Listing commented | **64.3%** — 2,503 comments over 3,893 instructions |
| Routines below the 10% bar | **0** of 548 |
| Pictures checked against the emulator's VRAM | logo **0** bytes different, table **0**, title **1** |

## What is in here

    src/pingpong.asm          the listing, generated
    src/pingpong.notes        what is understood: data blocks and comments
    src/pingpong.entries      the entry points, each with its reason
    src/pingpong.nocode       the ranges that are not code
    tools/                    the tracer, the listing generator and the checks
    tests/                    36 tests over the listing and the site
    docs/                     the site, in English and Spanish

The cartridge itself is **not** distributed. Put it in the root as
`pingpong.rom`; `make comprueba` verifies its sha256.

## Rebuilding it

    make

Traces the flow, writes the listing, reassembles it and checks that the result
is the ROM byte for byte, then runs the sanity checks and the tests. See
[Getting started](https://antxiko.github.io/KonamisPingPong-disassembly/GETTING-STARTED.html).

## Some of what turned up

- **The right half of the table is not stored anywhere.** It is drawn by
  mirroring the left one, byte by byte, through a routine that reverses the
  eight bits of each one.
- **Every animation frame carries the pointer to its own patterns right behind
  it.** That accounts for 3,135 bytes, and it checks out two independent ways.
- **The whole of table tennis scoring, in BCD**: 21 points, win by two, deuce
  at 20, service every five points and ends changed at 10 in the decider.
- **A sine table** whose two readers sit exactly a quarter of a wave apart, so
  one table gives both sine and cosine.
- **Konami's hidden mark** in the last fifteen bytes, a finding of
  **Manuel Pazos**.

All of it, with the measurement next to each claim, in
[Findings](https://antxiko.github.io/KonamisPingPong-disassembly/FINDINGS.html).

## The pictures are drawn from the ROM

There is not one screen capture in this repository. `tools/graficos.py` builds
the screens by running in Python the same steps the Z80 runs, and
`tools/coteja_vram.py` compares the result byte for byte against a VRAM dump
taken from openMSX.

## Licence

The tools, the notes and the site are published under the MIT licence (see
[LICENSE](LICENSE)). The code and artwork of the game remain the property of
their authors and of Konami; see [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
