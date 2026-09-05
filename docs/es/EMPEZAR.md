# Empezar

El repositorio trae el listado ya generado, pero lo que de verdad importa es
que se puede **rehacer entero desde el cartucho** y que el resultado vuelve a
ser la ROM byte a byte. Eso es lo que hace que las notas se puedan creer.

## Lo que hace falta

- **Python 3** (nada más: ni una dependencia)
- **pasmo**, el ensamblador de Z80, para la prueba del reensamblado
- **make**
- Para las comprobaciones contra la máquina, **openMSX**

## El cartucho

No viaja con el repositorio. Hay que ponerlo en la raíz como `pingpong.rom`,
16.384 bytes exactos:

    8e0f57b2c52e85505505c1d4bb4643eb7311213676f0ecfe21dd06571fc0bbd5

Para comprobar que es el mismo:

    make comprueba

## Rehacerlo todo

    make

Eso encadena las cuatro cosas que importan:

| paso | qué hace |
|---|---|
| `make listado` | traza el flujo desde los puntos de entrada y escribe `src/pingpong.asm` |
| `make verify` | reensambla con pasmo y compara el sha256 con el del cartucho |
| `make sanity` | lo que el reensamblado NO puede cazar (ver abajo) |
| `make test` | los 36 tests |

## Por qué `make verify` no basta

El reensamblado demuestra que los **bytes** son los mismos, no que lo que
decimos de ellos sea cierto. Si una tabla de datos se leyera como código, el
binario saldría idéntico igual: lo único que cambiaría es la mentira del
listado.

Por eso `make sanity` comprueba tres cosas más:

- que ninguna zona declarada como datos aparezca trazada como código
- que ningún punto de entrada caiga dentro de una zona de datos
- que **no quede ni un byte del cartucho sin asignar**: código alcanzado más
  datos declarados tienen que sumar 16.384

## Las cifras

    make densidad

Da las dos que se publican: cuántas instrucciones llevan comentario y si queda
alguna rutina por debajo del 10 %.

## Las imágenes

    make imagenes

Dibuja las pantallas **desde los bytes de la ROM**, ejecutando en Python los
mismos pasos que corre el Z80. No hay ni una captura en este repositorio.

Y para comprobarlas contra la máquina de verdad:

    "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
        -cart pingpong.rom -script tools/omsx_vram.tcl
    python3 tools/coteja_vram.py pingpong.rom work/omsx/vram_01.bin logotipo

Eso vuelca los 16 KB de VRAM del emulador en varios instantes y los compara
byte a byte con los que monta `tools/graficos.py`.

## Los ficheros que se escriben a mano

Sólo tres, y los tres llevan dentro el porqué de cada decisión:

- `src/pingpong.entries` — los puntos de entrada que el trazado no puede
  deducir solo, cada uno con su justificación
- `src/pingpong.nocode` — los rangos que NO son código
- `src/pingpong.notes` — los nombres, los comentarios y los rangos de datos

Todo lo demás sale de ahí.
