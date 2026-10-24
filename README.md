# Rugby 3D

Juego arcade de rugby 3D hecho en Godot 4 (GDScript). Vista de cámara tipo
retransmisión televisiva, 5 vs 5, con IA para compañeros y rivales.

## Cómo ejecutar

- **Desde el ejecutable de Godot** (sin abrir el editor):
  ```
  Godot_v4.7.2-stable_win64.exe --path .
  ```
- **Desde el editor**: abrir `project.godot` con Godot 4.7+ y pulsar F5.

## Controles

| Tecla | Acción |
|-------|--------|
| WASD / Flechas | Mover jugador controlado |
| Shift | Sprint |
| Espacio | Pasar (¡solo hacia atrás o lateral!) |
| K | Patada larga |
| Esc / P | Pausa |
| R | Reiniciar (al final del partido) |

El jugador controlado (cono amarillo) es siempre el portador en ataque o el
defensor más cercano al balón en defensa.

## Reglas implementadas (simplificadas)

- **Try**: cruzar la línea de goal rival con el balón = +7 (conversión automática).
- **Pase adelantado**: penalizado, la posesión pasa al rival.
- **Placaje**: el defensor derriba al portador; el balón pasa al compañero más
  cercano, o hay turnover si el portador estaba aislado.
- **Touch**: salir por el lateral o la línea de pelota muerta = turnover.
- **Duración**: 2 tiempos de 2:30, con cambio de campo en el entretiempo.
- **Saque**: el equipo que concede puntos saca desde la mitad de cancha.

## Estructura

```
scenes/main.tscn      escena principal (todo se genera por código)
scripts/main.gd       gestor del partido: fases, marcador, reglas
scripts/field.gd      cancha: césped, líneas, postes, tribunas
scripts/player.gd     jugador: control por input + IA (apoyos, defensa, placajes)
scripts/ball.gd       balón con física: carries, pases, patadas
scripts/camera_rig.gd cámara broadcast que sigue el juego
scripts/ui.gd         marcador, reloj y mensajes
```

## Ideas para iterar

- Conversión pateable manual (en vez de automática)
- Rucks/mauls con más jugadores y contest real
- Offside y knock-on
- Sonido (silbato, público, impactos)
- Sprites/modelos 3D con animaciones en vez de cápsulas
- Multijugador local
