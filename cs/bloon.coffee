bloon =
	exp: 0,
	level: 1,
	next_lv_exp: 100,
	lv_total_exp: 0,
	level_cap: 100,
	# Hard ceiling for the Bloon's own level. `level_cap` can be raised by
	# Goodra, so clamp against this absolute bound wherever a cap is applied.
	# Unbounded, the Bloon's `next_lv_exp = level * level * 100` curve overflows
	# a double (level^2 > 1.79e308 at level ~1.34e153), which would stop level-ups
	# entirely and freeze the tick loop.
	MAX_BLOON_LEVEL: 999,

	level_up: ->
		return if @level >= @MAX_BLOON_LEVEL
		@level += 1
		@lv_total_exp += @next_lv_exp
		@next_lv_exp = @level * @level * 100
		recalc_gpc()
		update_all_numbers()

	gain_exp: (exp) ->
		@exp += exp
		cap = Math.min(@level_cap, @MAX_BLOON_LEVEL)
		if @level >= cap
			@exp = @lv_total_exp if @exp > @lv_total_exp
			return
		# level_up() rewrites the HUD, so bound the loop: a huge exp grant must
		# never spin the main thread. 100k levels is far past any reachable cap.
		guard = 0
		while @exp >= @lv_total_exp + @next_lv_exp and @level < cap
			do @level_up
			break if (guard += 1) >= 100000


sliggoo =
	exp: 0,
	level: 0,
	next_lv_exp: 25,
	lv_total_exp: 0,

	level_up: ->
		@level += 1
		@lv_total_exp += @next_lv_exp
		@next_lv_exp = (@level + 5) * (@level + 5)

	gain_exp: (exp) ->
		@exp += exp
		# bound the level-up loop per call: astronomic exp grants (prestige
		# totals) must never freeze the browser in one tick
		guard = 0
		while @exp >= @lv_total_exp + @next_lv_exp
			do @level_up
			break if (guard += 1) > 1000000


goodra =
	exp: 0,
	level: 0,
	next_lv_exp: 1000,
	lv_total_exp: 0,

	level_up: ->
		@level += 1
		@lv_total_exp += @next_lv_exp
		@next_lv_exp = @level * 30 + 1000

	gain_exp: (exp) ->
		@exp += exp
		guard = 0
		while @exp >= @lv_total_exp + @next_lv_exp
			do @level_up
			break if (guard += 1) > 1000000

@bloon = bloon
@sliggoo = sliggoo
@goodra = goodra
