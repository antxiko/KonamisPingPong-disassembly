# Open questions

Every byte of the cartridge is accounted for and every routine carries a
comment, but that does not mean everything is understood. What is still open,
without dressing it up:

## Blocks whose limits are measured and whose use is not

For these we know **who loads them and where they end** -from the loader and
from where the next block starts- but not what each byte is for:

| block | bytes | who loads it |
|---|---|---|
| 0x4B7A | 13 | 0x4B6E, which copies them into the sprite buffer |
| 0x4B87 | 8 | 0x419B, and they are the small "KONAMI" on the title |
| 0x5886 | 40 | 0x5849, eight bytes from 0x5886 plus **three times** the level |
| 0x5C58..0x5C6D | 21 | four different loaders, all in the machine's play |
| 0x6A9C / 0x6AA8 | 12 and 12 | 0x6A85 and 0x6A53, the force and reach of a shot |

The 0x5886 one is the oddest: the stretches **overlap**, because the index
advances by three and eight bytes are copied. That is measured, but whether the
overlap is deliberate or there are simply spare bytes has not been settled.

## The three blocks at 0x4D0A

0x4CF6 copies 21 bytes to 0xE07C from three starts -0x4D0A, 0x4D1B and 0x4D2C-
that are **17 bytes** apart. So each copy takes four bytes of the next one.
They are declared that way, with the overlap stated, but whether anyone reads
those four extra bytes is not known.

## What exactly separates the five levels

The level is known to come in at three places: the trajectory table at 0x5D37
-five levels by six zones-, the points threshold at 0x5C5E and the easiest
level's latch. What has **not** been measured is how much each of the three
shows in an actual match, or which weighs most.

## The other table of twelve

The table at 0x6225 has twelve entries and matches to the byte by the
first-entry fit, just like the scene one. It dispatches the phases of a rally.
But the twelve have not been walked one by one in the emulator to see which
comes up when: what there is, is the reading of the code.

## The four side scripts

0x6D15 points at four scripts that draw two vertical columns at the sides of
the table, on a diagonal. What they paint and who picks them is known -bit 2 of
the frame clock, so they **flicker**- but not what they represent: the crowd,
the net seen edge-on, or the edge of the room.

## What is settled and might look open

- **VRAM being the other way round** is not a quirk of this cartridge: the
  eight register bytes are identical to Road Fighter's, whose whole skeleton
  this one shares. Checked, not assumed.
- **The two writes into ROM** at 0x4013 and 0x4052 do nothing, and it is not
  that they are not understood: ROM cannot be written, and that is that.
- **The one byte that does not match** on the title screen against the emulator
  is a problem of when the dump was taken, not of the format.

## If you know something

If you know the answer to any of these -or find an error in what is published-
it would be welcome: the point of this series is that the listing can be
believed, and for that it has to be correctable.
