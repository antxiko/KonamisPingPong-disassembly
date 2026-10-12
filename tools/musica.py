#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `arranca_melodia` (0x5113, A = numero; `suena_si_hay_partida`,
0x5108, solo suena en partida) y corre `late_el_sonido` (0x5195), que la
interrupcion llama cada cuadro. Tres voces de 15 bytes desde 0xE010; la copia
del registro 7 del PSG, en 0xE03D.
Uso:  musica.py registros 0xAE [cuadros] | mp3 0xAE f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xBF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0xA5, "La pieza del 0x42E2", "The tune at 0x42E2", "`L_42E2`"),
    P(0xAE, "La pieza del 0x6921", "The tune at 0x6921", "`L_6921`"),
] + [P(n, "Pista 0x%02X de la tabla" % n, "Table track 0x%02X" % n, TABLA)
     for n in (0xA3, 0xA4, 0xAD, 0xAF, 0xB0, 0xB1, 0xB2, 0xB3)]

PAGINA = motor_musica.pagina_basica(
    "`late_el_sonido`, 0x5195, y `arranca_melodia`, 0x5113, que le reparte "
    "los canales; lo llama la interrupción",
    "`late_el_sonido`, 0x5195, and `arranca_melodia`, 0x5113, which hands it "
    "the channels; the interrupt calls it",
    "C-BIOS MSX1 japonés",
    [("la pieza 0xAE entera, 194 cuadros",
      "tune 0xAE, whole, 194 frames"),
     ("la pieza 0xA5, sus primeros 221 cuadros de 318",
      "tune 0xA5, its first 221 frames of 318")],
    [("Cómo se pide una pieza",
      "`arranca_melodia` recibe el número en A y respeta la melodia que ya "
      "suene; `suena_si_hay_partida` hace lo mismo solo en partida (bit 6 "
      "de 0xE002). Los números bajos son efectos y del 0x97 en adelante "
      "hay música. Cada voz ocupa quince bytes desde 0xE010 y 0xE03D guarda "
      "la copia del mezclador del PSG, que el arranque deja en 0xB8. Las "
      "pistas «de la tabla» están en la tabla de pistas pero ninguna rutina "
      "las pide con un `ld a`; se omiten la 0xA6, la 0xA7 y la 0xAC, de "
      "minutos de duración y casi sin notas.",
      "How a piece is asked for",
      "`arranca_melodia` takes the number in A and respects the melody that "
      "is already playing; `suena_si_hay_partida` does the same only in a "
      "game (bit 6 of 0xE002). Low numbers are effects and from 0x97 up "
      "there is music. Each voice takes fifteen bytes from 0xE010 and 0xE03D "
      "holds the copy of the PSG mixer, which start-up leaves at 0xB8. The "
      "tracks marked «in the table» are in the track table but no routine "
      "asks for them with an `ld a`; 0xA6, 0xA7 and 0xAC, minutes long and "
      "nearly without notes, are left out.")])

CFG = dict(rom="pingpong.rom", org=0x4000, frame=0x5195, pide=0x5113,
           ram=(0xE010, 0xE03E), ram0=[(0xE03D, 0xB8)],
           excluye=[0xE019, 0xE028, 0xE037], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0xAE, 194, None), (0xA5, 318, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
