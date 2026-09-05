# El cartucho

## La ficha

| | |
|---|---|
| Juego | Konami's Ping Pong |
| Casa | Konami, 1985 |
| Referencia | **RC-731** |
| Tamaño | 16.384 bytes |
| Máquina | MSX1 |
| Página | 1 (0x4000..0x7FFF) |
| sha256 | `8e0f57b2c52e85505505c1d4bb4643eb7311213676f0ecfe21dd06571fc0bbd5` |

## La cabecera

Los dieciséis primeros bytes son la cabecera de todo cartucho de MSX:

    41 42 6C 40 00 00 00 00 00 00 00 00 00 00 00 00
    "A" "B"  INIT     STATEMENT  DEVICE   TEXT   reservado

"AB" es la firma, y detrás va la dirección de INIT: **0x406C**. Las otras tres
entradas están a cero, así que el cartucho no añade instrucciones al BASIC ni
declara dispositivo.

## INIT no arranca ningún bucle

Lo que hace 0x406C cabe en veinte instrucciones:

1. cierra la interrupción y pone el modo 1
2. escribe un `jp` (0xC3) en 0xFD9A y la dirección 0x4019 en 0xFD9B, que es el
   gancho **H.KEYI**
3. pone la pila en 0xE400
4. borra los 0x400 bytes de variables desde 0xE000
5. echa el cerrojo de (0xE005), monta la pantalla, lo suelta
6. abre la interrupción y se queda en `jr $`

Y ahí se queda para siempre. **Todo el juego cuelga de la interrupción**, una
vez por cuadro, colgado de H.KEYI.

## El reparto de los 16 KB

| | bytes | |
|---|---|---|
| código alcanzado | 7.676 | 46,85 % |
| datos identificados | 8.708 | 53,15 % |
| sin explicar | **0** | 0,00 % |

## La pantalla

Los ocho registros del VDP salen de la tabla de 0x47D6, que 0x47C5 vuelca en
R0..R7:

    02 E2 0E 7F 07 76 03 E4

| reg | valor | qué dice |
|---|---|---|
| R0 | 0x02 | SCREEN 2 |
| R1 | 0xE2 | 16K, pantalla activa, interrupción, **sprites de 16x16** |
| R2 | 0x0E | tabla de NOMBRES en 0x3800 |
| R3 | 0x7F | COLOR: base 0x0000, máscara 0x03FF |
| R4 | 0x07 | PATRONES: base 0x2000, máscara 0x03FF |
| R5 | 0x76 | atributos de sprite en 0x3B00 |
| R6 | 0x03 | patrones de sprite en 0x1800 |
| R7 | 0xE4 | tinta 14 sobre fondo 4 |

**R3 y R4 no son direcciones**: son una base y una máscara. Descifrados dejan
la VRAM al revés de lo acostumbrado, con el COLOR abajo y los PATRONES arriba:

| | |
|---|---|
| 0x0000..0x17FF | COLOR |
| 0x1800..0x1FFF | patrones de sprite |
| 0x2000..0x37FF | PATRONES |
| 0x3800..0x3AFF | NOMBRES |
| 0x3B00..0x3B7F | atributos de sprite |

Leerlos como direcciones da el reparto cambiado, y con él las formas salen
bien y los colores a franjas. Aquí no hay que fiarse de la lectura: los
destinos medidos de **todos** los bloques comprimidos caen dentro de este
reparto y no del otro, y el propio cartucho lo confirma dos veces llenando de
0xF0 la zona de 0x0080 y de 0x70 la de 0x1600 -valores que sólo tienen sentido
como color-.

R7 vale 0xE4 -fondo azul- mientras está el logotipo de la casa, y 0x4B4B lo
cambia a 0xE0 -negro- antes de pintar la elección de jugadores.

## La RAM

El juego usa 0x400 bytes desde 0xE000, y los borra enteros al arrancar. Los
sitios que más aparecen:

| dirección | qué guarda |
|---|---|
| 0xE000 / 0xE001 | la escena y el escalón dentro de ella |
| 0xE002 | el modo: bit 5 dos jugadores, bit 6 en partida |
| 0xE003 | el reloj de cuadros, que no se pone a cero nunca |
| 0xE004 | la cuenta atrás de la subescena |
| 0xE005 | el cerrojo de reentrada de la interrupción |
| 0xE008 / 0xE009 | el mando del jugador 1: flancos y estado crudo |
| 0xE048 / 0xE049 | los del jugador 2 |
| 0xE010.. | los tres canales de sonido, quince bytes cada uno |
| 0xE070.. | el buffer de atributos de sprite, 0x80 bytes |
| 0xE100.. | la pelota: posición, velocidad y estado |
| 0xE130 | la fase del punto |
| 0xE132 / 0xE133 | los dos tanteos, en BCD |
| 0xE160.. / 0xE180.. | los dos jugadores |

## La marca oculta

Los últimos quince bytes:

    AC B8 9D AC B8 9A 00 98 00 9F 94 89 0C 31 AA

Doce de título en katakana -コナミのピンポン-, la longitud 0x0C y el 0x31 de
**RC-731**. Delante van 70 bytes de 0xFF, que es lo que sobró del cartucho.

Esa marca la descubrió **Manuel Pazos**, y de él es el hallazgo.
