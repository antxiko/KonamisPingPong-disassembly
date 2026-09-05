# In the emulator

The pictures on this site do not come from the emulator: `tools/graficos.py`
draws them from the bytes of the ROM. The emulator is used for the opposite,
which is **checking that those pictures are true**.

## Dumping the real VRAM

    "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
        -cart pingpong.rom -script tools/omsx_vram.tcl

The script lets the game run and, at seven moments spread over the startup and
the match, dumps into `work/omsx/`:

- the **16 KB of VRAM** exactly as the VDP sees them
- the **eight registers**, which say where each table is
- the **variables** that say what was being drawn: scene, subscene, mode,
  level, game, rally phase and both scores

It sets no breakpoints at all: the dumps are scheduled on emulated time, which
is the only thing that does not choke the emulator. And it carries a real-time
watchdog, so a broken script cannot leave it hanging.

## Comparing

    python3 tools/coteja_vram.py pingpong.rom work/omsx/vram_01.bin logotipo
    python3 tools/coteja_vram.py pingpong.rom work/omsx/vram_03.bin titulo
    python3 tools/coteja_vram.py pingpong.rom work/omsx/vram_04.bin nivel

It compares the four tables -colour, patterns, names and sprite patterns- byte
for byte, and says in which and in how many bytes they differ. What comes out
today:

| scene | bytes different out of 16,384 |
|---|---|
| logo | **0** |
| table with the menu | **0** |
| title | **1** |

The one byte left is the eighth of the small "KONAMI" at 0x3868: the dump
catches that animation half-way through, it is not a format error.

Sprite attributes are not compared: they change every frame. What is compared
is the scenery, which is what `graficos.py` claims to reproduce.

## What the registers confirmed

    info_00  regs 02 E2 0E 7F 07 76 03 E4   scene 0, subscene 2
    info_02  regs 02 E2 0E 7F 07 76 03 E0   scene 1, subscene 3
    info_04  regs 02 E2 0E 7F 07 76 03 E0   scene 3, subscene 5

Three things at once:

- the eight registers are the ones the table at 0x47D6 says, with **R3=0x7F and
  R4=0x07**, that is, VRAM the other way round
- **R7 changes from 0xE4 to 0xE0** between the logo and the player selection
- and in the demo, `level 3`, which confirms the fixed value set by 0x40A9

## Playing it

With any MSX1 emulator and the cartridge in page 1. With openMSX:

    openmsx -machine Philips_VG_8020 -cart pingpong.rom

Player 1's keys are the arrows and the space bar; player 2 has their own keys,
spread over four rows of the matrix, and both joystick ports work too.
