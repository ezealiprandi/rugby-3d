extends SceneTree

# Test rápido del torneo: simula las 11 fechas y verifica la tabla.
var game: RugbyGame
var frames := 0
var done := false


func _init() -> void:
	var scene := load("res://scenes/main.tscn")
	game = scene.instantiate()
	root.add_child(game)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 5:
		game.menu.hide_menu()
		game.start_match(0, 0, "tournament")   # away se sobreescribe con el fixture
	if frames > 20 and not done:
		done = true
		# simular todas las fechas del torneo sin jugarlas de verdad
		for f in 11:
			game.away_idx = game.tour_fixture[game.tour_pos]
			game._record_result(0, game.away_idx,
				game.rng.randi_range(10, 30), game.rng.randi_range(5, 28),
				game.rng.randi_range(1, 4), game.rng.randi_range(0, 4))
			game._sim_fecha()
			game.tour_pos += 1
		print(game._table_text())
		var pj_total := 0
		for d in game.tour_table:
			pj_total += d.played
		assert(pj_total == 11 * 12, "PJ inconsistente: %d" % pj_total)
		print("TOUR TEST OK — PJ total: %d" % pj_total)
		return true
	if frames > 600:
		print("TIMEOUT")
		return true
	return false
