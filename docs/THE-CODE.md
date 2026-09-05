# The code

## One whole frame

Everything hangs off H.KEYI, so the program is whatever fits between two
interrupts. The heartbeat at 0x4019 always does the same:

    call RDVDP              acknowledge the interrupt
    di / call 0x5195 / ei   the sound, which cannot miss a frame
    bit 0,(0xE005)          the reentry latch
      inc (hl)              set it
      call 0x46AC           check whether ends must be swapped
      call 0x47E3           read the controls
      call 0x409F           run whichever scene is due
      ld (0xE005),0         and clear it
    call RDVDP / call m,0x5195   one more sound pass

The latch matters: if a frame takes longer than a frame lasts, the next one is
skipped whole instead of running half-way through.

## Dispatch, on two levels

**The scene** is dispatched by 0x4062, the dispatcher this family of Konami
cartridges shares:

    add a,a / pop hl / call 0x4058 / ld e,(hl) / inc hl / ld d,(hl)
    ex de,hl / jp (hl)

The `pop hl` retrieves its own return address, and that **is** the table: it
sits glued right behind the `call`. How many entries it has is not estimated;
it is pinned by the fact that its first entry points just past the table. Both
tables match to the byte:

    0x40C9 + 8*2  = 0x40D9, and its first entry is 0x40D9
    0x6225 + 12*2 = 0x623D, and its first entry is 0x623D

**The subscene** uses no table at all. It is picked by walking down a chain of
`djnz`:

    L_40D9: djnz L_40EE      <- subscene 0
            ...
    L_40EE: djnz L_40FA      <- subscene 1
            ...

Each step is two bytes, and the block that runs is the one where B hits zero.
Twenty-five steps in fifty bytes, no comparisons and no table.

To move from one step to the next there are two endings repeated all over the
listing: 0x4260 bumps (0xE001), and 0x425D also leaves A frames of wait in
(0xE004).

## The interpreters

The cartridge carries three, and all three read a script out of the ROM.

### The labels, and their four doors

The format is `[VRAM destination, word] [pattern indices...]`, with 0xFE to
jump to another destination and 0xFF to finish. The pattern index is the ASCII
code minus 0x20, so the font is laid out like ASCII from the space up.

The neat part is that one loop covers four things, depending on which door you
come in by:

| entry | header | mask |
|---|---|---|
| 0x4764 | read from the script | 0xFF, paints |
| 0x476C | already in HL | whatever it carries |
| 0x475C | already in HL | 0xFF, paints |
| 0x4760 | read from the script | **0x00, erases** |

The fourth is the clever one: with the mask at zero the `and c` leaves the byte
at zero, so **the very script that wrote the label erases it**.

## The decompressor

    0x00           closes the block
    0x01..0x7F     the byte that follows, repeated that many times
    0x80           new VRAM destination (two bytes)
    0x81..0xFF     literal of (command & 0x7F) bytes

It writes to the VDP port with one `out (c),a` per byte, keeping the port in C'
so it does not disturb the caller's registers.

And on top there are two loops that repeat it: 0x4735 with B=2 and 0x4739 with
B=3, raising the destination by 0x800 each pass. The `push de` / `pop de`
returns DE to the start of the block, so **it is the same block being painted
into all three thirds** of SCREEN 2.

### The second decompressor

0x5E9B has the same commands minus the 0x80 -it cannot change destination
mid-way- and, above all, **it is not handed the block in DE**: it fetches it
from a pointer. That is what links each frame with its patterns, and it is told
in [Findings](FINDINGS.html).

## The sound

Three channels of fifteen bytes each from 0xE010. A tune can take one, two or
three, and the tune number doubles as its **priority**: 0x5121 compares the low
six bits of what is playing against the new one and will not override it if it
is lower.

The tune script is read by nibbles:

| command | what it does |
|---|---|
| bare 0x20 | envelope: writes registers 11, 12 and 13 |
| 0x2x | duration |
| 0x1x | noise: period to register 6 and the mixer opened |
| 0xDx | duration multiplier |
| 0xEx | octave |
| 0xFx | starting volume |
| 0xFE / 0xFF | close |
| anything else | note: the high nibble is the note, 0 to 12 |

The note becomes a period through the twelve-semitone table at 0x532D, and the
octave is applied by **doubling** the period as many times as (ix+5) says. That
they are twelve equal-tempered semitones is not an assumption: the ratio
between consecutive notes comes out between 1.050 and 1.071, against the 1.0595
of the twelfth root of two.

The 12 is not a note: it is the rest.

## The arithmetic

The Z80 can neither multiply nor divide, so the cartridge does it by hand:

- **0x6F65** multiplies 8x8 by adding and shifting eight times
- **0x6F71** applies it to both halves for 16x8
- **0x6F88** divides by subtracting and shifting sixteen

With those three and three fixed factors, 0x6BA1 projects the three table
coordinates onto a screen row and column.

## How a control is read

The joystick is read through the PSG -0x8F to register 15 to select the port,
14 to read- and the keyboard with SNSMAT. The good bit is that 0x4812 **builds
from the keys the very same bit map the joystick gives**, shuffling each row
into place with `rrca`. From there on the rest of the game cannot tell one from
the other.

And 0x47F9 is the filter that turns state into fresh presses: it stores what is
current, XORs it with what was there and ANDs with what is current. What is
left are the rising edges, and they go one byte below the raw state.
