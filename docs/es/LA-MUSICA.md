# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`late_el_sonido`, 0x5195, y `arranca_melodia`, 0x5113, que le reparte los canales; lo llama la interrupción) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la pieza 0xAE entera, 194 cuadros;
- la pieza 0xA5, sus primeros 221 cuadros de 318.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`arranca_melodia` recibe el número en A y respeta la melodia que ya suene; `suena_si_hay_partida` hace lo mismo solo en partida (bit 6 de 0xE002). Los números bajos son efectos y del 0x97 en adelante hay música. Cada voz ocupa quince bytes desde 0xE010 y 0xE03D guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero ninguna rutina las pide con un `ld a`; se omiten la 0xA6, la 0xA7 y la 0xAC, de minutos de duración y casi sin notas.

## Las músicas

**La pieza del 0x42E2** (0xA5)

Lo pide `L_42E2`; dura 5,3 s.

<audio controls preload="none" src="../audio/musica_A5.mp3?v=ad3ee796"></audio>

**La pieza del 0x6921** (0xAE)

Lo pide `L_6921`; dura 3,2 s.

<audio controls preload="none" src="../audio/musica_AE.mp3?v=9aee56bc"></audio>

**Pista 0xA3 de la tabla** (0xA3)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 25,6 s.

<audio controls preload="none" src="../audio/musica_A3.mp3?v=0921c777"></audio>

**Pista 0xA4 de la tabla** (0xA4)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 25,6 s.

<audio controls preload="none" src="../audio/musica_A4.mp3?v=8dd7c5d2"></audio>

**Pista 0xAD de la tabla** (0xAD)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 3,2 s.

<audio controls preload="none" src="../audio/musica_AD.mp3?v=23630620"></audio>

**Pista 0xAF de la tabla** (0xAF)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_AF.mp3?v=90b0570b"></audio>

**Pista 0xB0 de la tabla** (0xB0)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_B0.mp3?v=65f8aafc"></audio>

**Pista 0xB1 de la tabla** (0xB1)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_B1.mp3?v=9b8e09e7"></audio>

**Pista 0xB2 de la tabla** (0xB2)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_B2.mp3?v=4d9fe5c6"></audio>

**Pista 0xB3 de la tabla** (0xB3)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_B3.mp3?v=8fea822d"></audio>
