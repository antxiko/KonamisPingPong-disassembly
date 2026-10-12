# The music

Everything you hear here comes from running the cartridge's own sound engine (`late_el_sonido`, 0x5195, and `arranca_melodia`, 0x5113, which hands it the channels; the interrupt calls it) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- tune 0xAE, whole, 194 frames;
- tune 0xA5, its first 221 frames of 318.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`arranca_melodia` takes the number in A and respects the melody that is already playing; `suena_si_hay_partida` does the same only in a game (bit 6 of 0xE002). Low numbers are effects and from 0x97 up there is music. Each voice takes fifteen bytes from 0xE010 and 0xE03D holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the track table but no routine asks for them with an `ld a`; 0xA6, 0xA7 and 0xAC, minutes long and nearly without notes, are left out.

## The tunes

**The tune at 0x42E2** (0xA5)

Asked for by `L_42E2`; lasts 5.3 s.

<audio controls preload="none" src="audio/musica_A5.mp3?v=ad3ee796"></audio>

**The tune at 0x6921** (0xAE)

Asked for by `L_6921`; lasts 3.2 s.

<audio controls preload="none" src="audio/musica_AE.mp3?v=9aee56bc"></audio>

**Table track 0xA3** (0xA3)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 25.6 s.

<audio controls preload="none" src="audio/musica_A3.mp3?v=0921c777"></audio>

**Table track 0xA4** (0xA4)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 25.6 s.

<audio controls preload="none" src="audio/musica_A4.mp3?v=8dd7c5d2"></audio>

**Table track 0xAD** (0xAD)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 3.2 s.

<audio controls preload="none" src="audio/musica_AD.mp3?v=23630620"></audio>

**Table track 0xAF** (0xAF)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_AF.mp3?v=90b0570b"></audio>

**Table track 0xB0** (0xB0)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_B0.mp3?v=65f8aafc"></audio>

**Table track 0xB1** (0xB1)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_B1.mp3?v=9b8e09e7"></audio>

**Table track 0xB2** (0xB2)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_B2.mp3?v=4d9fe5c6"></audio>

**Table track 0xB3** (0xB3)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_B3.mp3?v=8fea822d"></audio>
