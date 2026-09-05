# En el emulador

Las imágenes de esta web no salen del emulador: las dibuja `tools/graficos.py`
desde los bytes de la ROM. El emulador se usa para lo contrario, que es
**comprobar que esas imágenes son ciertas**.

## Volcar la VRAM de verdad

    "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
        -cart pingpong.rom -script tools/omsx_vram.tcl

El guion deja correr el juego y, en siete instantes repartidos por el arranque
y la partida, vuelca en `work/omsx/`:

- los **16 KB de VRAM** tal como los ve el VDP
- los **ocho registros**, que dicen dónde está cada tabla
- las **variables** que dicen qué se estaba dibujando: escena, subescena, modo,
  nivel, set, fase del punto y los dos tanteos

No pone ni un punto de ruptura: los volcados van por reloj emulado, que es lo
único que no ahoga al emulador. Y lleva un perro guardián de tiempo real, para
que un guion roto no lo deje colgado.

## Comparar

    python3 tools/coteja_vram.py pingpong.rom work/omsx/vram_01.bin logotipo
    python3 tools/coteja_vram.py pingpong.rom work/omsx/vram_03.bin titulo
    python3 tools/coteja_vram.py pingpong.rom work/omsx/vram_04.bin nivel

Compara las cuatro tablas -color, patrones, nombres y patrones de sprite- byte
a byte, y dice en cuál y en cuántos bytes se diferencian. Lo que sale hoy:

| escena | bytes distintos de 16.384 |
|---|---|
| logotipo | **0** |
| mesa con el menú | **0** |
| título | **1** |

El byte que queda es el octavo del "KONAMI" pequeño de 0x3868: el volcado pilla
esa animación a medias, no es un fallo de formato.

Los atributos de sprite no se comparan: cambian cada cuadro. Lo que se compara
es el decorado, que es lo que `graficos.py` dice reproducir.

## Lo que los registros confirmaron

    info_00  regs 02 E2 0E 7F 07 76 03 E4   escena 0, subescena 2
    info_02  regs 02 E2 0E 7F 07 76 03 E0   escena 1, subescena 3
    info_04  regs 02 E2 0E 7F 07 76 03 E0   escena 3, subescena 5

Tres cosas de una vez:

- los ocho registros son los que dice la tabla de 0x47D6, con **R3=0x7F y
  R4=0x07**, o sea la VRAM al revés
- **R7 cambia de 0xE4 a 0xE0** entre el logotipo y la elección de jugadores
- y en la demostración, `nivel 3`, que confirma el valor fijo de 0x40A9

## Jugar

Con cualquier emulador de MSX1 y el cartucho en la página 1. Con openMSX:

    openmsx -machine Philips_VG_8020 -cart pingpong.rom

Las teclas del jugador 1 son las flechas y el espacio; el jugador 2 tiene sus
propias teclas, repartidas por cuatro filas de la matriz, y también valen los
dos puertos de joystick.
