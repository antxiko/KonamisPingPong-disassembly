# Konami's Ping Pong (Konami, 1985) — desensamblado comentado

Desensamblado completo y comentado del cartucho de MSX1 **Konami's Ping Pong**
(Konami, número de catálogo **RC-731**, 16 KB), reproducible byte a byte.

**Web: <https://antxiko.github.io/KonamisPingPong-disassembly/es/>** · [In English](README.md)

|  |  |
|---|---|
| Del binario explicado | **100 %** — 0 bytes sin asignar, de 16.384 |
| Reensambla | **byte a byte**, al mismo sha256 |
| Del listado comentado | **64,3 %** — 2.503 comentarios sobre 3.893 instrucciones |
| Rutinas por debajo del listón del 10 % | **0** de 548 |
| Imágenes cotejadas contra la VRAM del emulador | logotipo **0** bytes distintos, mesa **0**, título **1** |

## Qué hay aquí

    src/pingpong.asm          el listado, generado
    src/pingpong.notes        lo que se entiende: bloques de datos y comentarios
    src/pingpong.entries      los puntos de entrada, cada uno con su porqué
    src/pingpong.nocode       los rangos que no son código
    tools/                    el trazador, el generador del listado y las comprobaciones
    tests/                    36 tests sobre el listado y la web
    docs/                     la web, en castellano e inglés

El cartucho **no** se distribuye. Hay que ponerlo en la raíz como
`pingpong.rom`; `make comprueba` verifica su sha256.

## Rehacerlo

    make

Traza el flujo, escribe el listado, lo reensambla y comprueba que el resultado
es la ROM byte a byte; después pasa las comprobaciones de sanidad y los tests.
Ver [Empezar](https://antxiko.github.io/KonamisPingPong-disassembly/es/EMPEZAR.html).

## Algo de lo que apareció

- **La mitad derecha de la mesa no está guardada.** Se dibuja reflejando la
  izquierda, byte a byte, con una rutina que le da la vuelta a los ocho bits de
  cada uno.
- **Cada fotograma lleva pegado detrás el puntero a sus propios patrones.** De
  ahí salen 3.135 bytes, y encaja por dos caminos independientes.
- **El reglamento del tenis de mesa entero, en BCD**: 21 puntos, ganar por dos,
  deuce a 20, saque cada cinco puntos y cambio de campo a los 10 en el set
  decisivo.
- **Una tabla de seno** cuyos dos lectores están separados exactamente un cuarto
  de onda, así que de una sola tabla salen el seno y el coseno.
- **La marca oculta de Konami** en los últimos quince bytes, hallazgo de
  **Manuel Pazos**.

Todo ello, con la medida al lado de cada afirmación, en
[Hallazgos](https://antxiko.github.io/KonamisPingPong-disassembly/es/HALLAZGOS.html).

## Las imágenes están dibujadas desde la ROM

No hay ni una captura de pantalla en este repositorio. `tools/graficos.py`
monta las pantallas ejecutando en Python los mismos pasos que corre el Z80, y
`tools/coteja_vram.py` compara el resultado byte a byte con un volcado de la
VRAM tomado de openMSX.

## Licencia

Las herramientas, las notas y la web se publican con licencia MIT (ver
[LICENSE](LICENSE)). El código y los gráficos del juego siguen siendo de sus
autores y de Konami; ver [AVISO-LEGAL.md](AVISO-LEGAL.md).
