# El código

## Un cuadro entero

Todo cuelga de H.KEYI, así que el programa es lo que cabe entre dos
interrupciones. El latido de 0x4019 hace siempre lo mismo:

    call RDVDP              acepta la interrupcion
    di / call 0x5195 / ei   el sonido, que no puede perder un cuadro
    bit 0,(0xE005)          el cerrojo de reentrada
      inc (hl)              se echa
      call 0x46AC           mira si toca cambiar de campo
      call 0x47E3           lee los mandos
      call 0x409F           corre la escena que toque
      ld (0xE005),0         y se suelta
    call RDVDP / call m,0x5195   una pasada mas de sonido

El cerrojo importa: si un cuadro tarda más de lo que dura un cuadro, el
siguiente se salta entero en vez de entrar a medias.

## El despacho, en dos niveles

**La escena** la reparte 0x4062, que es el despachador de esta familia de
cartuchos de Konami:

    add a,a / pop hl / call 0x4058 / ld e,(hl) / inc hl / ld d,(hl)
    ex de,hl / jp (hl)

El `pop hl` recupera su propia dirección de retorno, y ésa **es** la tabla:
va pegada detrás del `call`. Cuántas entradas tiene no se estima, lo fija el
encaje de que su primera entrada apunte justo detrás de la tabla. Las dos que
hay cuadran al byte:

    0x40C9 + 8*2  = 0x40D9, y su primera entrada es 0x40D9
    0x6225 + 12*2 = 0x623D, y su primera entrada es 0x623D

**La subescena** no gasta tabla. Se elige bajando por una cadena de `djnz`:

    L_40D9: djnz L_40EE      <- subescena 0
            ...
    L_40EE: djnz L_40FA      <- subescena 1
            ...

Cada escalón son dos bytes, y el trozo que se ejecuta es aquel en que B llega
a cero. Veinticinco escalones en cincuenta bytes, sin comparaciones y sin
tabla.

Para pasar de un escalón al siguiente hay dos remates que se repiten por todo
el listado: 0x4260 sube (0xE001), y 0x425D además deja A cuadros de espera en
(0xE004).

## Los intérpretes

El cartucho lleva tres, y los tres leen un guion de la ROM.

### Los rótulos, y sus cuatro puertas

El formato es `[destino en VRAM, word] [índices de patrón...]`, con 0xFE para
saltar a otro destino y 0xFF para terminar. El índice de patrón es el código
ASCII menos 0x20, así que la fuente está ordenada como el ASCII a partir del
espacio.

Lo bonito es que el mismo bucle sirve para cuatro cosas, según se entre por
una puerta o por otra:

| entrada | cabecera | máscara |
|---|---|---|
| 0x4764 | la lee del guion | 0xFF, pinta |
| 0x476C | ya viene en HL | la que traiga |
| 0x475C | ya viene en HL | 0xFF, pinta |
| 0x4760 | la lee del guion | **0x00, borra** |

La cuarta es la buena: con la máscara a cero el `and c` deja el byte en cero,
así que **el mismo guion que escribió el rótulo lo borra**.

### El descompresor

    0x00           cierra el bloque
    0x01..0x7F     el byte que sigue, repetido esa cuenta
    0x80           destino de VRAM nuevo (dos bytes)
    0x81..0xFF     literal de (mandato & 0x7F) bytes

Escribe al puerto del VDP con un `out (c),a` por byte, con el puerto guardado
en C' para no tocar los registros de quien llama.

Y encima hay dos bucles que lo repiten: 0x4735 con B=2 y 0x4739 con B=3,
subiendo el destino 0x800 en cada vuelta. El `push de` / `pop de` devuelve DE
al principio del bloque, así que **es el mismo bloque el que se pinta en los
tres tercios** de SCREEN 2.

### El segundo descompresor

0x5E9B tiene los mismos mandatos menos el 0x80 -no puede cambiar de destino a
media faena- y, sobre todo, **no recibe el bloque en DE**: lo saca de un
puntero. Eso es lo que enlaza cada fotograma con sus patrones, y está contado
en [Hallazgos](HALLAZGOS.html).

## El sonido

Tres canales de quince bytes cada uno desde 0xE010. Una melodía puede ocupar
uno, dos o tres, y el número de melodía hace de **prioridad**: 0x5121 compara
los seis bits bajos de la que suena con los de la nueva y no la pisa si es
menor.

El guion de melodía se lee por nibbles:

| mandato | qué hace |
|---|---|
| 0x20 pelado | envolvente: escribe los registros 11, 12 y 13 |
| 0x2x | duración |
| 0x1x | ruido: periodo al registro 6 y paso abierto en el mezclador |
| 0xDx | multiplicador de duración |
| 0xEx | octava |
| 0xFx | volumen de arranque |
| 0xFE / 0xFF | cierran |
| resto | nota: el nibble alto es la nota, del 0 al 12 |

La nota se convierte en periodo con la tabla de doce semitonos de 0x532D, y la
octava se aplica **duplicando** el periodo tantas veces como diga (ix+5). Que
son doce semitonos temperados no es una suposición: la razón entre notas
consecutivas sale entre 1,050 y 1,071, contra el 1,0595 de la duodécima raíz
de dos.

El 12 no es una nota: es el silencio.

## La aritmética

El Z80 no multiplica ni divide, así que el cartucho lo hace a mano:

- **0x6F65** multiplica 8x8 sumando y desplazando ocho veces
- **0x6F71** lo aplica a las dos mitades para 16x8
- **0x6F88** divide restando y desplazando dieciséis

Con esas tres y tres factores fijos, 0x6BA1 proyecta las tres coordenadas de
la mesa en fila y columna de pantalla.

## Cómo se lee un mando

El joystick se lee por el PSG -0x8F al registro 15 para elegir el puerto, el
14 para leer- y el teclado con SNSMAT. Lo bueno es que 0x4812 **arma con las
teclas el mismo mapa de bits que da el joystick**, colocando cada fila en su
sitio a base de `rrca`. A partir de ahí el resto del juego no distingue uno de
otro.

Y 0x47F9 es el filtro que convierte el estado en pulsaciones nuevas: guarda lo
de ahora, hace XOR con lo de antes y AND con lo de ahora. Lo que queda son los
flancos de subida, y van un byte por debajo del estado crudo.

## Código compartido con otros cartuchos de Konami

Este desensamblado se ha comparado, instrucción por instrucción, con
todos los demás de Konami de la serie. Cuenta un bloque cuando las
mismas instrucciones, al menos seis desde una etiqueta hasta su `ret`
o su salto sin condición, están en los dos cartuchos; las direcciones
no se miran, porque cambian de un cartucho a otro. De los otros 57,
**54** tienen al menos un bloque en común con este; estos son los
que más comparten:

| Cartucho | Bloques | Instrucciones | Por ejemplo (aquí = allí) |
|---|---:|---:|---|
| [Yie Ar Kung-Fu II](https://antxiko.github.io/YieArKungFu2-disassembly/es/) | 25 | 284 | `lee_teclado_1` (0x4812) = `lee_las_filas_7_y_8_del_teclado` |
| [The Goonies](https://antxiko.github.io/Goonies-disassembly/es/) | 22 | 235 | `descomprime` (0x477B) = `guion_rle` |
| [Road Fighter](https://antxiko.github.io/RoadFighter-disassembly/es/) | 22 | 258 | `descomprime` (0x477B) = `descomprime_con_destino_dentro` |
| [Hyper Sports 3](https://antxiko.github.io/HyperSports3-disassembly/es/) | 21 | 243 | `lee_teclado_1` (0x4812) = `teclado_del_jugador_1` |
| [Knightmare](https://antxiko.github.io/Knightmare-disassembly/es/) | 20 | 209 | `pinta_rotulo` (0x4764) = `pinta_texto` |
| [Konami’s Soccer](https://antxiko.github.io/KonamisSoccer-disassembly/es/) | 20 | 221 | `pinta_rotulo` (0x4764) = `escribe_un_rotulo` |
| [Konami's Boxing](https://antxiko.github.io/Boxing-disassembly/es/) | 19 | 202 | `pinta_rotulo` (0x4764) = `pinta_texto` |
| [Q*bert](https://antxiko.github.io/Qbert-disassembly/es/) | 18 | 181 | `descomprime` (0x477B) = `guion_rle` |
| [Yie Ar Kung-Fu](https://antxiko.github.io/YieArKungFu-disassembly/es/) | 17 | 185 | `lee_teclado_1` (0x4812) = `lee_el_teclado` |
| [Nemesis / Gradius](https://antxiko.github.io/Nemesis-disassembly/es/) | 16 | 170 | `descomprime` (0x477B) = `descomprime_con_destino` |

La matriz entera, los 58 cartuchos entre sí, está en
[Las rutinas](https://antxiko.github.io/MSX-disassembly-database/es/LAS-RUTINAS.html) de la base de datos de la
serie, con el método y el programa que la mide.
