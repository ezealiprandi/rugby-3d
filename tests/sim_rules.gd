extends SceneTree

# Test de integración headless: ejecuta el partido y fuerza todos los eventos
# reglamentarios. Uso:
#   godot --headless --path . --script tests/sim_rules.gd
# Imprime "TEST OK" si todo el flujo funciona.

var game: RugbyGame
var frames := 0
var st := 0
var sub := 0


func _init() -> void:
	var scene := load("res://scenes/main.tscn")
	game = scene.instantiate()
	root.add_child(game)


func _press(action: String) -> void:
	Input.action_press(action)


func _release(action: String) -> void:
	Input.action_release(action)


func _process(_delta: float) -> bool:
	frames += 1
	if frames > 12000:
		print("TEST FAIL: timeout en estado %d (phase=%s)" % [st, game.phase])
		return true

	match st:
		0:
			game.menu.hide_menu()
			game.start_match(0, 3)   # Tucumán RC vs Natación (campeón)
			st = 1
		1:
			if game.phase == RugbyGame.Phase.PLAY:
				print("> kickoff ok, PLAY")
				game._event_scrum(0, Vector3(10, 0, 5), "TEST scrum")
				st = 2
		2:
			if game.phase == RugbyGame.Phase.PLAY:
				print("> scrum ok")
				game._event_lineout(1, 15.0, -1.0, "TEST lineout")
				st = 3
		3:
			if game.phase == RugbyGame.Phase.PLAY:
				print("> lineout ok")
				game.ball.set_carrier(game.players[4])   # lock del team0
				game._start_maul(0)
				st = 14
		14:
			if game.phase == RugbyGame.Phase.PLAY:
				print("> maul ok")
				game._event_dropout(0, "TEST dropout")
				st = 4
		4:
			if game.phase == RugbyGame.Phase.PLAY:
				print("> dropout ok")
				var c: RugbyPlayer = game.players[20]   # jugador team1
				game.ball.set_carrier(c)
				game.on_tackle(game.players[0], c)
				st = 5
		5:
			if game.phase == RugbyGame.Phase.PLAY:
				print("> tackle/ruck ok")
				game.on_knock_on(game.players[2])
				st = 6
		6:
			if game.phase == RugbyGame.Phase.PLAY:
				print("> knock-on ok")
				game.adv_t = -1.0                     # cancela la ventaja (test)
				var c: RugbyPlayer = game.players[5]    # team0 ataca +Z
				game.ball.set_carrier(c)
				c.global_position = Vector3(5, 0, 52)   # en el in-goal rival
				st = 7
		7:
			if game.phase == RugbyGame.Phase.CONVERSION \
					and game.conv_state == RugbyGame.ConvState.AIM:
				_press("pass")
				st = 8
				sub = 0
		8:
			sub += 1
			if sub == 2:
				_release("pass")
			if game.conv_state == RugbyGame.ConvState.POWER \
					and game.conv_power > 0.55:
				_press("pass")
				st = 9
				sub = 0
		9:
			sub += 1
			if sub == 2:
				_release("pass")
			if game.phase == RugbyGame.Phase.PLAY:
				print("> try+conversión jugador ok (score=%s)" % str(game.score))
				var c: RugbyPlayer = game.players[25]   # team1 ataca -Z
				game.ball.set_carrier(c)
				c.global_position = Vector3(-4, 0, -52)
				st = 10
		10:
			if game.phase == RugbyGame.Phase.PLAY:
				print("> try+conversión IA ok (score=%s)" % str(game.score))
				game.clock = game.half_len - 1.0
				st = 11
		11:
			if game.phase == RugbyGame.Phase.BETWEEN \
					or game.phase == RugbyGame.Phase.END:
				print("> entretiempo ok (half=%d)" % game.half)
				st = 12
		12:
			if game.phase == RugbyGame.Phase.PLAY:
				game.clock = game.half_len - 1.0
				st = 13
		13:
			if game.phase == RugbyGame.Phase.END:
				print("> final ok")
				print("TEST OK")
				return true
	return false
