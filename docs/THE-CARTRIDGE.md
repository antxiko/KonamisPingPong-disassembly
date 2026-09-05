# The cartridge

## The facts

| | |
|---|---|
| Game | Konami's Ping Pong |
| Publisher | Konami, 1985 |
| Reference | **RC-731** |
| Size | 16,384 bytes |
| Machine | MSX1 |
| Page | 1 (0x4000..0x7FFF) |
| sha256 | `8e0f57b2c52e85505505c1d4bb4643eb7311213676f0ecfe21dd06571fc0bbd5` |

## The header

The first sixteen bytes are the header every MSX cartridge carries:

    41 42 6C 40 00 00 00 00 00 00 00 00 00 00 00 00
    "A" "B"  INIT     STATEMENT  DEVICE   TEXT   reserved

"AB" is the signature, and behind it the address of INIT: **0x406C**. The other
three entries are zero, so the cartridge adds no BASIC statements and declares
no device.

## INIT starts no loop

What 0x406C does fits in twenty instructions:

1. disables interrupts and sets mode 1
2. writes a `jp` (0xC3) at 0xFD9A and the address 0x4019 at 0xFD9B, which is
   the **H.KEYI** hook
3. puts the stack at 0xE400
4. clears the 0x400 bytes of variables from 0xE000
5. sets the (0xE005) latch, builds the screen, clears it
6. enables interrupts and sits on `jr $`

And there it stays forever. **The whole game hangs off the interrupt**, once
per frame, off H.KEYI.

## How the 16 KB break down

| | bytes | |
|---|---|---|
| code reached | 7,676 | 46.85 % |
| data identified | 8,708 | 53.15 % |
| unexplained | **0** | 0.00 % |

## The screen

The eight VDP registers come from the table at 0x47D6, which 0x47C5 pours into
R0..R7:

    02 E2 0E 7F 07 76 03 E4

| reg | value | what it says |
|---|---|---|
| R0 | 0x02 | SCREEN 2 |
| R1 | 0xE2 | 16K, display on, interrupt on, **16x16 sprites** |
| R2 | 0x0E | NAME table at 0x3800 |
| R3 | 0x7F | COLOUR: base 0x0000, mask 0x03FF |
| R4 | 0x07 | PATTERNS: base 0x2000, mask 0x03FF |
| R5 | 0x76 | sprite attributes at 0x3B00 |
| R6 | 0x03 | sprite patterns at 0x1800 |
| R7 | 0xE4 | ink 14 on background 4 |

**R3 and R4 are not addresses**: they are a base and a mask. Decoded, they lay
out VRAM the other way round from the usual, with COLOUR low and PATTERNS
high:

| | |
|---|---|
| 0x0000..0x17FF | COLOUR |
| 0x1800..0x1FFF | sprite patterns |
| 0x2000..0x37FF | PATTERNS |
| 0x3800..0x3AFF | NAMES |
| 0x3B00..0x3B7F | sprite attributes |

Reading them as addresses gives the layout swapped, and with it the shapes come
out right and the colours in stripes. There is no need to take the reading on
trust here: the measured destinations of **every** compressed block fall inside
this layout and not the other, and the cartridge itself confirms it twice by
filling 0x0080 with 0xF0 and 0x1600 with 0x70 -values that only make sense as
colour-.

R7 is 0xE4 -blue background- while the company logo is up, and 0x4B4B changes
it to 0xE0 -black- before painting the player selection.

## RAM

The game uses 0x400 bytes from 0xE000, and clears them all at startup. The
addresses that come up most:

| address | what it holds |
|---|---|
| 0xE000 / 0xE001 | the scene and the step within it |
| 0xE002 | the mode: bit 5 two players, bit 6 in play |
| 0xE003 | the frame clock, never reset |
| 0xE004 | the subscene countdown |
| 0xE005 | the interrupt reentry latch |
| 0xE008 / 0xE009 | player 1's control: edges and raw state |
| 0xE048 / 0xE049 | player 2's |
| 0xE010.. | the three sound channels, fifteen bytes each |
| 0xE070.. | the sprite attribute buffer, 0x80 bytes |
| 0xE100.. | the ball: position, velocity and state |
| 0xE130 | the phase of the rally |
| 0xE132 / 0xE133 | the two scores, in BCD |
| 0xE160.. / 0xE180.. | the two players |

## The hidden mark

The last fifteen bytes:

    AC B8 9D AC B8 9A 00 98 00 9F 94 89 0C 31 AA

Twelve of title in katakana -コナミのピンポン-, the length 0x0C and the 0x31 of
**RC-731**. Before them sit 70 bytes of 0xFF, whatever was left over of the
cartridge.

That mark was discovered by **Manuel Pazos**, and the finding is his.
