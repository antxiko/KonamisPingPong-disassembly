# The game

Konami's Ping Pong is table tennis seen from behind one player, with the table
in perspective and the opponent at the far end. It came out in 1985 as the
16 KB RC-731 cartridge for MSX1.

![The title screen](imagenes/titulo.png)

## One player or two

The title screen offers both, and the cursor moves between them. What you pick
ends up in a single bit: (0xE042) indexes a two-byte table -0x40 and 0x60- and
whichever comes out goes into (0xE002). **Bit 5 of that byte is the only thing
the rest of the game looks at** to know whether the other side is a person or
the machine.

## Five levels

The level menu is painted on top of the table once it is up.

![The level menu](imagenes/nivel.png)

The five values it offers -1, 3, 5, 7 and 9- live in the table at 0x461F, and
the cursor is pattern 0x88 placed at the column it names. Internally the level
is the index, 0 to 4.

The level does not change the speed of the ball: it changes **how the machine
plays**. It comes in at three different places:

- in the trajectory table, which says where it returns the ball
- in the points threshold past which it starts pushing
- and, on the easiest level, in a latch that makes it miss every other shot

In the attract demo the level is not the one you picked: it is a **fixed 3**,
set by 0x40A9.

## The rules are the real ones

They are all inside the cartridge, and they can be read off the code because
the score is kept in BCD:

- a game is won at **21**
- you must **win by two**, and if both reach 21 the score resets
- **deuce** at 20-all
- the **service changes every five points**, by checking the units digit of
  the sum of both scores
- and in the third game the players **change ends at 10**

A match is best of three. The ordinals announcing each one -1ST, 2ND and 3RD-
are stored as three six-byte scripts.

## What the umpire calls

Four labels, picked by the state of the rally: **LET**, **NET**, **OUT** and
**IN**. Each has its own tune in a sister table, indexed by the same number.

And the other text the cartridge carries: LOVE ALL, GAME, DEUCE, GAME SET,
WIN, CHANGE COURT and LEVEL.

## Changing ends

When it is time to swap sides, the cartridge does not move the players: it
**swaps the controls**. 0x46EB exchanges one player's two control bytes with
the other's, and from then on each one drives the figure on the other side.

## The table

![The table](imagenes/pista.png)

Half of it is drawn and the other half comes from mirroring it. The picture
above is built by running in Python the same steps the cartridge runs, and it
does not differ by **a single byte** from the one the emulator holds in its
VRAM.
