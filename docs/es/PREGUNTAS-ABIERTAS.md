# Preguntas abiertas

Todo byte del cartucho está asignado y todas las rutinas llevan comentario,
pero eso no quiere decir que todo esté entendido. Lo que queda sin cerrar, sin
disimularlo:

## Bloques cuyo límite está medido y cuyo uso no

De éstos se sabe **quién los carga y dónde acaban** -por el cargador y por
dónde empieza el bloque siguiente-, pero no para qué sirve cada byte:

| bloque | bytes | quién lo carga |
|---|---|---|
| 0x4B7A | 13 | 0x4B6E, que los copia al buffer de sprites |
| 0x4B87 | 8 | 0x419B, y son el "KONAMI" pequeño del título |
| 0x5886 | 40 | 0x5849, ocho bytes desde 0x5886 más **tres veces** el nivel |
| 0x5C58..0x5C6D | 21 | cuatro cargadores distintos, todos del juego de la máquina |
| 0x6A9C / 0x6AA8 | 12 y 12 | 0x6A85 y 0x6A53, la fuerza y el alcance del golpe |

El de 0x5886 es el más raro: los tramos **se solapan**, porque el índice avanza
de tres en tres y se copian ocho bytes. Eso está medido, pero no se ha cerrado
si el solape es intencionado o si sencillamente sobran bytes.

## Los tres bloques de 0x4D0A

0x4CF6 copia 21 bytes a 0xE07C desde tres arranques -0x4D0A, 0x4D1B y 0x4D2C-
que están a **17 bytes** unos de otros. O sea que cada copia se lleva cuatro
bytes del siguiente. Están declarados así, con el solape dicho, pero no se sabe
si esos cuatro bytes de más los lee alguien.

## Qué distingue exactamente los cinco niveles

Se sabe que el nivel entra en tres sitios: la tabla de trayectorias de 0x5D37
-cinco niveles por seis zonas-, el umbral de puntos de 0x5C5E y el pestillo del
nivel más fácil. Lo que **no** se ha medido es cuánto se nota cada uno de los
tres en una partida de verdad, ni cuál pesa más.

## La otra tabla de doce

La tabla de 0x6225 tiene doce entradas y cuadra al byte con el encaje de la
primera entrada, igual que la de escenas. Reparte las subfases del punto. Pero
las doce no se han recorrido una a una en el emulador para ver cuál sale
cuándo: lo que hay es la lectura del código.

## Los cuatro guiones laterales

0x6D15 apunta a cuatro guiones que dibujan dos columnas verticales a los lados
de la mesa, en diagonal. Se sabe qué pintan y quién los elige -el bit 2 del
reloj, así que **parpadean**-, pero no qué representan: si son el público, la
red vista de canto o el borde de la sala.

## Lo que ya está cerrado y podría parecer abierto

- **La VRAM al revés** no es una rareza de este cartucho: los ocho bytes de
  registros son idénticos a los de Road Fighter, con el que comparte el
  armazón entero. Está comprobado, no supuesto.
- **Las dos escrituras a la ROM** de 0x4013 y 0x4052 no hacen nada, y no es que
  falte entenderlas: la ROM no admite escritura y punto.
- **El byte que no cuadra** en la pantalla de título contra el emulador es un
  problema del instante del volcado, no del formato.

## Si sabes algo

Si conoces la respuesta a cualquiera de éstas -o encuentras un error en lo que
está publicado-, se agradece que lo digas: la idea de esta serie es que el
listado se pueda creer, y para eso hay que poder corregirlo.
