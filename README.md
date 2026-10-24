# Rugby Tucumano 3D

Juego de rugby 3D hecho en Godot 4 (GDScript). **15 vs 15**, vista de cámara
tipo retransmisión televisiva, con los clubes de la **Unión de Rugby de
Tucumán** y su indumentaria oficial.

## Cómo ejecutar

```
Godot_v4.7.2-stable_win64.exe --path .
```

O abrir `project.godot` con el editor Godot 4.7+ y pulsar F5.

## Clubes (colores oficiales URT)

| Club | Sede | Camiseta |
|------|------|----------|
| Tucumán Rugby Club | Yerba Buena | Cuadros verde y negro |
| Universitario RC | S.M. de Tucumán | Azul y gris |
| Los Tarcos RC | S.M. de Tucumán | Roja |
| **Club Natación y Gimnasia** ★ | S.M. de Tucumán | Blanca, rayas azul/roja (campeón 2026) |
| Tucumán Lawn Tennis | S.M. de Tucumán | Blanca, azul y amarilla |
| Cardenales RC | S.M. de Tucumán | Roja, cruz negra |
| Huirapuca S.C. | Concepción | Verde y roja |
| Jockey Club de Tucumán | Yerba Buena | Blanca, bordó y celeste |
| Lince RC | S.M. de Tucumán | Gris y roja |
| Corsarios RC | S.M. de Tucumán | Negra |
| Bajo Hondo RC | S.M. de Tucumán | Negra y naranja |
| Aguará Guazú | Aguilares | Azul y roja |

## Controles

| Tecla | Acción |
|-------|--------|
| WASD / Flechas | Mover jugador controlado |
| Shift | Sprint |
| Espacio | Pasar (¡hacia atrás!) / confirmar en conversión |
| K | Patada larga |
| Enter | Menú: confirmar |
| Esc / P | Pausa / volver en menú |
| R / M | Revancha / volver al menú (al final del partido) |

Controlás siempre al portador en ataque o al defensor más cercano en defensa
(cono amarillo).

## Conversión (estilo Rugby 25)

Tras cada try, la patada se juega desde la perpendicular de donde se apoyó:

1. **Dirección**: la aguja barre izquierda-derecha — Espacio para fijar.
2. **Potencia**: la barra sube y baja — Espacio para patear.

El balón pega en los postes y el travesaño con física real. Si el equipo rival
marca, su apertura convierte automáticamente (más difícil desde el costado).

## Reglas implementadas

- **Try** (+5) y **conversión** (+2) pateable
- **Pase adelantado** y **knock-on** (recepción fallida) → **scrum**
- **Scrum**: los packs se forman en el punto, sale el medioscrum (9)
- **Touch** → **lineout**: filas de forwards, hooker tira, 18% de robo
- **Placaje** → **ruck**: apoyos atan, defensores respetan línea de offside,
  sale el 9 (o turnover si no hay apoyo)
- **Penales**: 10% de infracción en el ruck → penal jugado rápido 10m adelante
- **Pelota muerta / in-goal propio** → **drop-out de 22**
- **2 tiempos** de 3:00 con cambio de campo; saque del equipo que concede puntos

Simplificaciones deliberadas: conversión automática para la IA, sin mark ni
offside de patada, y el scrum/lineout no son contestados en profundidad.

## Estadio

Cancha reglamentaria (70×120m con in-goals), postes con protectores,
banderines de esquina, tribunas con público (MultiMesh), torres de luz,
vallas publicitarias, bancos de suplentes y logo URT en mitad de cancha.

## Estructura

```
scenes/main.tscn        escena raíz (todo se genera por código)
scripts/main.gd         gestor del partido: fases, reglas, conversión
scripts/teams.gd        clubes URT: colores, ciudad, rating
scripts/menu.gd         menú principal y selector de equipos
scripts/field.gd        estadio completo
scripts/player.gd       jugador: input + IA (apoyos, defensa, rucks, formaciones)
scripts/ball.gd         física del balón
scripts/camera_rig.gd   cámara broadcast / órbita menú / cámara de conversión
scripts/ui.gd           marcador, reloj, mensajes, medidor de conversión
tests/sim_rules.gd      test headless de todos los eventos reglamentarios
```

## Test headless

```
godot --headless --script tests/sim_rules.gd   # debe imprimir TEST OK
```

Y con `-- --auto` al ejecutar el juego se salta el menú (partido TRC vs NYG).

## Ideas para iterar

- Drop goals y penales al palo
- Mark (recepción limpia) y offside de patada
- Mauls y scrums contestados con física de empuje
- Sonido (silbato, público, impactos) y comentario
- Modelos 3D animados en vez de cápsulas
- Modo torneo URT
