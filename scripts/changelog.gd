class_name RugbyChangelog
extends RefCounted

# Versión actual del juego — se muestra en el menú y en esta pantalla.
const VERSION := "v0.6"

# Historial de cambios, de la versión más nueva a la más vieja.
# Para publicar una versión nueva: subir VERSION y agregar una entrada
# [versión, título, [lista de cambios]] al principio de este array.
const HISTORY := [
	["v0.6", "Presentación + jugabilidad pulida", [
		"Replay animado: se graban las rotaciones de brazos/piernas — ya no se ven jugadores congelados",
		"Intro de repetición estilo noticiero con espera de 3 segundos",
		"Sistema de conversión NUEVO: retícula 3D en la H, línea de trayectoria, A/D dirección, W/S altura, zona verde de potencia",
		"Selección de jugador: Automática (sin flickering), Mixta o Manual con click del mouse",
		"Reloj acelerado tipo FIFA: cada tiempo se completa en ~5 min reales",
		"Tiempos de partido: 5/7/10/15/20/40 minutos por tiempo",
		"Stamina tipo FIFA: solo gasta al sprintar; sin energía el jugador camina",
		"Pausa congela TODO de verdad (jugadores, pelota, cancha, cámara)",
		"Placaje de pie al apretar F de cerca; lance al piso solo de lejos",
		"Palomita al try con F cerca del in-goal, animación boca abajo",
		"Pelota ubicada dentro de los brazos del portador",
		"Fix: resolución en pantalla completa y textos centrados a cualquier resolución",
	]],
	["v0.5", "Calidad visual y atmósfera", [
		"Cielo por horario: día azul, atardecer dorado, noche con faros encendidos que iluminan la cancha",
		"Texturas procedurales a 2048px: camisetas, pelota, cemento, vallas",
		"Barro sutil en la zona de tránsito cuando llueve + pelota resbaladiza",
		"Sonidos nuevos: lluvia ambiente, pasos, placaje, barrida, patada",
		"Cabina de transmisión URT TV con presentadores en la tribuna",
		"Planteles actualizados con nombres del Centro de Alto Rendimiento URT 2025",
		"Placaje de pie en la IA (ya no barren), marker dorado del controlado",
		"Niebla reducida — imagen limpia sin filtro gris",
	]],
	["v0.4", "Presentación broadcast", [
		"Presentador URT TV pre-partido + bug EN VIVO permanente",
		"Pantalla de formaciones XV titular con nombres reales por casaca",
		"Replay broadcast con cámara orbitando y letterbox",
		"Tarjeta del goleador con número y apellido + tabla de goleadores del torneo",
		"Tarjetas amarillas/rojas en el marcador + stats del primer tiempo",
		"Jugador del Partido calculado por tries/placajes/metros",
		"Barra de energía del jugador controlado + suplentes al entretiempo",
		"Cámara 'Detrás' estilo Rugby 25 + transiciones suaves",
		"Opción de resolución: 1280×720 a 1920×1080",
	]],
	["v0.3", "Presentable para la URT", [
		"Modelos más detallados: ojos con pupila, mandíbula, pelo, vendas, brazalete de capitán",
		"Físico por posición: pilares anchos, segundas altos, wings veloces",
		"Identidad fija por apellido real (piel, pelo, barba, botines)",
		"Pelota ovalada real de rugby con costura y cordones",
		"Menú extendido con grilla de los 12 clubes URT",
		"Repositorio público open source con licencia MIT",
		"Botón Salir + homenaje 'al rugby tucumano'",
	]],
	["v0.2", "Gameplay jugable (G1–G4)", [
		"Controles reales: correr, sprint, pases Q/E/Espacio, patadas, placajes",
		"IA con espaciado: no se amontonan, defensa formada del lado correcto",
		"Rucks dirigidos: elegís a dónde abrir con Q/E",
		"Scrums, lineouts con salto, mauls con drive al try",
		"Drop-out 22, knock-on, advantage, penales, sin bin",
		"Animaciones de correr, placaje, lance y palomita",
		"Práctica libre sin reloj",
	]],
	["v0.1", "Alfa — primer prototipo", [
		"Partido 15 vs 15 en estadio procedural con tribunas y crowd",
		"12 clubes de la URT con colores y kits propios",
		"Marcador, reloj y conversión básica",
		"Cámara broadcast, árbitro y jueces de touch",
		"Menú principal con selección de equipos",
	]],
]
