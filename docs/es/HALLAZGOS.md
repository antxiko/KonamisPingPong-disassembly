# Hallazgos

Lo que apareció al desmontarlo, con la medida al lado de cada cosa.

## La mitad derecha de la mesa no está guardada

La rutina de 0x7060 copia de VRAM a VRAM pasando cada byte por 0x47A6, que le
da la vuelta a sus ocho bits:

    L_47A6: push bc / ld c,a / ld b,008h
    L_47AA: rr c / rla / djnz L_47AA
            pop bc / ret

Sale por la derecha de C y entra por la izquierda de A: el tile del revés. Y
el bucle que la llama, en 0x703B, **recupera el origen con un `pop` en cada
vuelta y sólo sube el destino**, así que el mismo trozo se refleja en los tres
tercios de la pantalla.

Son 768 bytes reflejados en la pista y 512 más en el fondo del título. Se ve en
la hoja de patrones:

![Los patrones del segundo tercio](../imagenes/tiles_pista_1.png)

Donde el primer tercio pone **KONAMI**, el reflejo pone **IMANOK**.

## El cartucho se defiende: protección anticopia

Dos instrucciones del arranque escriben dentro del propio cartucho:

- **0x4013** deja un `pop hl` y un `ret` encima del `djnz` de 0x40EE.
  El `0xC9` que escribe es un `ret`, y tampoco se lo inventa: lo lee de
  otro sitio de la propia ROM.
- **0x4052** deja un cero en 0x40F8, que no es un dato: es el operando del `jp`
  de 0x40F7. En memoria eso lo convierte en `jp 00000h`, un reinicio en seco.

**Ninguna de las dos hace nada aquí.** El cartucho corre desde ROM, y la ROM no admite
escritura: por eso parecen código muerto. No lo son. Un cartucho pirateado es una
copia cargada en **RAM**, y ahí la escritura sí cuela y rompe el juego. Que no
haga nada en el original es justo la gracia.

No es una idea suelta de este cartucho: el mismo par —una escritura sobre un
`djnz` y otra sobre el operando de un `jp`— aparece en nueve cartuchos de esta serie, siempre en las mismas dos rutinas del arranque, y la segunda sola en uno más. Las identificó **Manuel
Pazos** en su desensamblado del RC-727, donde las llamó `ReadKeys_AC` y
`VRAM_writeAC`.

## Cada fotograma lleva pegado detrás el puntero a sus patrones

El segundo descompresor, 0x5E9B, empieza así:

    inc hl / ld e,(hl) / inc hl / ld d,(hl) / ex de,hl    HL = el bloque
    ld e,(hl) / inc hl / ld d,(hl) / ex de,hl / inc de    HL = el destino

No recibe el bloque: lo **saca de un puntero**, y ese puntero va pegado detrás
de los datos de sprite de cada fotograma. Un fotograma es entonces:

    [dy, dx, patron] por sprite, un 0x81 si lleva menos, y el puntero

De ahí salen los 3.135 bytes de 0x73A7..0x7D25, y encaja por **dos caminos
independientes**:

1. encadenando bloques con el descompresor desde 0x73A7, la cadena cae
   **exactamente** en 0x7D26 -donde empieza el bloque siguiente, que ya se
   conocía por otro lado- en cuarenta saltos
2. y los cuarenta punteros que llevan los fotogramas de las dos tablas son,
   uno por uno, esos cuarenta arranques

Veinte fotogramas para el jugador de cerca, que se dibuja con hasta cinco
sprites, y veinte para el del fondo, que se dibuja con dos o tres.

## El reglamento del tenis de mesa, en BCD

El tanteo se lleva en decimal codificado -0x6760 suma con `add a,001h / daa`-,
y leyéndolo así las reglas salen enteras:

| regla | dónde |
|---|---|
| el set se gana a 21 | `cp 021h` en 0x6891 |
| si los dos llegan a 21, el marcador se reinicia | 0x6829 |
| deuce al empate a 20 | `cp 020h` en 0x6819 |
| el saque cambia cada cinco puntos | 0x683D |
| cambio de campo a los 10 en el set decisivo | 0x46C8 |

El cambio de saque es lo más elegante: 0x683D **suma los dos tanteos**, hace
`daa` y mira si el dígito de las unidades es 0 o 5.

Y la comprobación de los dos puntos de diferencia acepta 0x02 **y también
0x08**. No es un error: la resta es binaria sobre BCD, así que 21 menos 19 da
0x08 y son dos puntos igual. Las dos formas que puede tomar una diferencia de
dos, según haya acarreo de nibble o no.

## Una tabla de seno, y de ella salen el seno y el coseno

0x6EAD son 92 bytes que suben de 12 a 255, bajan, pasan por cero y vuelven a
subir. Que es un seno está medido: los 31 valores del primer cuarto contra
255·sin(i·90/31) se desvían **4,7 como mucho**, sobre un recorrido de 255.

Y los dos sitios que la leen -0x6E99 y 0x6EA3- están separados **31
posiciones**, que es justo un cuarto de onda. De una sola tabla salen las dos
funciones.

## Un intérprete de rótulos con cuatro puertas

Las dos cosas que pueden variar son si el destino se lee del guion o llega ya
en HL, y si la máscara deja pasar los bytes o escribe ceros. Las cuatro
combinaciones tienen su entrada, y ocupan diez bytes en total:

    0x4764  ld c,0ffh  y cae en 0x4766      cabecera si, pinta
    0x476C  entra en el bucle               cabecera no
    0x475C  ld c,0ffh / jr 0x476C           cabecera no, pinta
    0x4760  ld c,000h / jr 0x4766           cabecera si, BORRA

Con la máscara a cero, el `and c` deja el byte en cero: **el mismo guion que
escribió el rótulo lo borra**, dejando su geometría.

## El logotipo de la casa no es una imagen

0x4A2F lo dibuja subiendo una fila en cada pasada -0xFFE0 es menos 0x20- y en
cada una suelta tres rachas de patrones **consecutivos**: tres desde 0x40, once
desde 0x43 y doce desde 0x4E, más doce ceros que borran el rastro de la pasada
anterior.

![El logotipo de la casa](../imagenes/logotipo.png)

Catorce pasadas, y arranca desde la fila de abajo.

## Dos escrituras que no llegan a ninguna parte

0x4013 escribe en 0x40EE y 0x4052 en 0x40F8. Las dos direcciones caen **dentro
de la propia ROM**, que no admite escritura: los dos `ld` se ejecutan en cada
partida y no cambian nada.

## El mismo armazón que Road Fighter

No es parecido: es el mismo, pieza por pieza. El despachador con la tabla
pegada detrás, las dos sumas de 8 sobre 16 bits, el intérprete de rótulos, el
descompresor y su bucle de tercios.

Y los **ocho bytes de los registros del VDP son idénticos**, uno por uno:
`02 E2 0E 7F 07 76 03 E4`. Allí están en 0x46A9 y aquí en 0x47D6. La VRAM al
revés no es, por tanto, un hallazgo de este cartucho: es una pieza más del
armazón que los dos comparten.

## Lo que costó cazar

Cuatro errores de dibujo que **mirar la imagen no cazaba**, y que sólo salieron
comparando byte a byte con la VRAM del emulador:

1. 0x48A6 carga `hl,00008h`, que en esta geometría es la tabla de **COLOR**:
   los quince tiles que llena son rectángulos lisos de color, y de ahí sale el
   suelo rojo de la pista. Leídos como patrones, la pantalla salía negra.
2. La pantalla de título **hereda la VRAM del logotipo**; entre pantalla y
   pantalla sólo se borra la tabla de nombres. Partir de cero daba 1.113 bytes
   distintos.
3. R7 vale 0xE4 -fondo azul- durante el logotipo y 0xE0 después.
4. La **"O" de PONG es un sprite**, no un tile: son dos sprites del mismo color
   en el mismo sitio. Sin pintarlos, el rótulo salía con un hueco.

Después de los cuatro, el logotipo y la mesa coinciden con la VRAM del emulador
en **cero bytes de diferencia**, y la pantalla de título en uno solo, que es el
octavo del "KONAMI" pequeño: el volcado pilla esa animación a medias.
