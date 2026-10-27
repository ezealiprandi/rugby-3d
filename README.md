# Rugby Tucumano 3D

Juego de rugby 3D hecho en Godot 4 (GDScript), estilo **Rugby 25**.
**15 vs 15**, vista de cámara broadcast, con los 12 clubes de la
**Unión de Rugby de Tucumán** y su indumentaria oficial generada por código.

## Cómo ejecutar

```
Godot_v4.7.2-stable_win64.exe --path .
```

O abrir `project.godot` con el editor Godot 4.7+ y pulsar F5.

## Clubes (colores oficiales URT)

| Club | Sede | Camiseta |
|------|------|----------|
| Tucumán Rugby Club | Yerba Buena | Cuadros verde y negro |
| Universitario RC | S.M. de Tucumán | Hoops azul y gris |
| Los Tarcos RC | S.M. de Tucumán | Roja, cuello blanco |
| **Club Natación y Gimnasia** ★ | S.M. de Tucumán | Blanca, doble franja azul/roja (campeón 2026) |
| Tucumán Lawn Tennis | S.M. de Tucumán | Hoops blanca, azul y amarilla |
| Cardenales RC | S.M. de Tucumán | Negra, cruz amarilla |
| Huirapuca S.C. | Concepción | Hoops verde y roja |
| Jockey Club de Tucumán | Yerba Buena | Blanca, doble franja bordó/celeste |
| Lince RC | S.M. de Tucumán | Hoops gris y roja |
| Corsarios RC | S.M. de Tucumán | Negra, cuello blanco |
| Bajo Hondo RC | S.M. de Tucumán | Hoops negra y naranja |
| Aguará Guazú | Aguilares | Hoops azul y roja |

## Modos de juego

- **AMISTOSO** — partido único entre los dos clubes que elijas
- **TORNEO URT** — campeonato de 11 fechas con tabla de posiciones real
  (4 pts victoria, 2 empate, bonus por 4+ tries y por perder <8).
  Se simulan los demás partidos de cada fecha
- **PRÁCTICA** — libre, sin reloj; M para salir

## Controles

| Tecla | Acción |
|-------|--------|
| WASD / Flechas | Mover jugador controlado |
| Shift | Sprint (¡gasta energía!) |
| Q / E | Pase a la izquierda / derecha |
| Espacio | Pase al apoyo más cercano / offload al ser placado / confirmar |
| F | Placaje (lance a voluntad) · en el ruck: competir por la pelota |
| X | Sidestep (amague lateral, difícil de placar) |
| B | Dummy pass (amague que congela defensores) |
| J | Fend |
| K | Patada larga · en penal: a los palos (+3) |
| T | En penal: patada al touch (lineout propio) |
| C | Grubber (rasante) |
| V | Up and under (bomb) |
| Z | Cross kick (al wing opuesto) |
| G | Drop goal (+3) |
| Esc / P | Pausa |
| R / M | Revancha / menú al final |

## Reglas implementadas

- **Try** (+5), **conversión** y **penal a los palos** con sistema
  dirección+potencia estilo Rugby 25; el balón choca con postes y travesaño
- **Replay broadcast** del try antes de la conversión (Espacio lo saltea)
- **Ventaja**: knock-on y pase adelantado dan ventaja antes del scrum
- **Scrum** que empuja metros + tight head steal (8%)
- **Lineout** con variantes: maul que conduce al try, tiro largo al 10, sale el 9
- **Maul** que avanza empujado por los forwards y puede colapsar → scrum
- **Ruck** con jackal (F para robar), robo por superioridad numérica y
  penales por "no soltó" y offside
- **Pick and go** de forwards desde el ruck
- **Penales**: tap rápido, a los palos o al touch
- **Tarjetas**: amarilla (sin bin 45") al 2° penal, **roja** al 4° acumulado
- **Placaje alto**: lanzarte al placaje puede costarte penal
- **Marca** en los 22 · **Drop-out de 22** · **Drop goal** (+3)
- **Fatiga**: el sprint cansa, los cansados corren más lento
- **Stats por jugador**: tries, placajes, metros; MVP y panel post-partido

## Ambiente

- Render **Forward+** (Vulkan): bloom, SSAO, tonemapping filmic, niebla
- Sorteo por partido de **día / atardecer / noche** (focos encendidos de noche)
- **Lluvia** aleatoria (30%): la pelota resbala → más knock-ons
- Confetti del color del club en los tries, equipo festejando si sos campeón
- Sonido procedural: silbato, murmullo de tribuna y festejo
- Árbitro siguiendo la jugada, jueces de touch, fotógrafos y camarógrafo
- Jugadores humanoides con número, casco de scrum en el front row,
  animación de carrera, placaje, salto de lineout y celebración

## Estructura

```
scenes/main.tscn        escena raíz (todo se genera por código)
scripts/main.gd         gestor del partido: fases, reglas, torneo, conversión
scripts/teams.gd        clubes URT: colores, rating y camisetas generadas
scripts/menu.gd         menú principal, modos y selector de equipos
scripts/field.gd        estadio, clima, horario, fotógrafos
scripts/player.gd       jugador: input + IA (formaciones, rucks, skills)
scripts/ball.gd         física del balón (pases, patadas, grubber, bombs)
scripts/camera_rig.gd   cámara broadcast / órbita menú / replay / conversión
scripts/ui.gd           marcador, conversión, stats post-partido
scripts/referee.gd      árbitro y jueces de touch
scripts/humanoid.gd     modelo humanoide compartido
tests/sim_rules.gd      test headless de todos los eventos reglamentarios
tests/sim_tour.gd       test headless del torneo y la tabla
tests/gen_audio.gd      generador procedural de los WAVs en assets/
```

## Tests headless

```
godot --headless --path . --script tests/sim_rules.gd   # debe imprimir TEST OK
godot --headless --path . --script tests/sim_tour.gd    # debe imprimir TOUR TEST OK
```

Y con `-- --auto` al ejecutar el juego se salta el menú.

## Contribuir

El código es **visible públicamente** (source-available): forks, PRs e
ideas son bienvenidos con fines de contribución. Distribuir o
comercializar el juego requiere autorización previa del autor
(ver [LICENSE](LICENSE)).

- Todo el juego se genera por código GDScript — no hay assets externos
  salvo los WAV procedurales de `assets/` (se regeneran con `tests/gen_audio.gd`).
- Antes de un PR, corré los dos tests headless y verificá `TEST OK`.
- Estructura por fases del partido en `scripts/main.gd` (`enum Phase`)
  y por club en `scripts/teams.gd` (`CLUBS` y `SQUADS`).

## Licencia

**Propietaria — todos los derechos reservados.** Podés ver, clonar y
modificar el código para uso personal o para contribuir al proyecto, pero
**distribuir, publicar, vender o usar comercialmente el juego requiere
autorización previa y por escrito del autor**
([@ezealiprandi](https://github.com/ezealiprandi)). Ver [LICENSE](LICENSE).
