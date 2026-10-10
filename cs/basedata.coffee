basedata =

	version: "0.354 (pre-alpha)",

	game_started: false,

	bloons: 0,

	total_bloons: 0,   # total bloons, counting ones used in purchases
	total_total_bloons: 0,   # total bloons, counting ones used in reset

	play_time: 0,   # play time in seconds of current session
	total_play_time: 0,   # total play time over all sessions

	last_save_time: new Date()	# date and time of last save, for perfect idle calc

	gps: 0,
	expps: 0,
	gpc: 1,

	sliggoo_gpsmult: 1.0,

	prestige_count: 0,   # number of prestiges performed (max 15)
	prestige_mult: 1.0,  # global earnings/battle damage multiplier: 2 ^ prestige_count

	prestige_threshold: (n) ->
		n = @prestige_count + 1 unless n?
		1e9 * Math.pow(100, n - 1)

	can_prestige: ->
		# thresholds count Bloons earned in the current run (total_bloons),
		# which resets on every prestige
		@prestige_count < 15 && @total_bloons >= @prestige_threshold()

	prestige: ->
		return false unless @can_prestige()
		@prestige_count += 1
		@prestige_mult = Math.pow(2, @prestige_count)
		# battle progress is a permanent track and survives prestige
		@reset(true)
		play_sound("upgrade")
		return true

	raindance_mult: 1.0,
	frenzy_clickmult: 1.0,
	frenzy_expmult: 1.0,

	clicks: 0,   # number of times the Great Bloon was clicked
	total_clicks: 0,

	# Compensation terms for compensated (Neumaier) summation: tiny gains on
	# huge balances no longer vanish into the 2^53 quantisation step of a
	# double, so balances stop drifting over long sessions. The true value of
	# each accumulator is always value + its compensation term.
	bloons_comp: 0,
	total_bloons_comp: 0,
	total_total_bloons_comp: 0,

	balance: -> @bloons + @bloons_comp

	earn: (n) ->
		@add_precise("bloons", n)
		@add_precise("total_bloons", n)
		@add_precise("total_total_bloons", n)

	spend: (n) ->
		# spending only reduces the balance; totals count earned bloons only
		@add_precise("bloons", -n)

	add_precise: (key, n) ->
		t = @[key] + n
		comp_key = key + "_comp"
		if Math.abs(@[key]) >= Math.abs(n)
			@[comp_key] += (@[key] - t) + n
		else
			@[comp_key] += (n - t) + @[key]
		@[key] = t

	click: ->

		if !@game_started
			@game_started = true

		gain = @gpc

		@earn(gain)
		@clicks += 1
		@total_clicks += 1
		bloon.gain_exp(bloon.level * @frenzy_expmult)
		return gain

	update: (ms) ->

		# While a boss fight is active, BpS production is halted and instead
		# channeled into damaging the boss (see battle.update).
		gain = if battle.active then 0 else @gps * ms / 1000
		@earn(gain)

		exp_gain = @expps * ms / 1000
		bloon.gain_exp (exp_gain)

		if @game_started
			@play_time += ms
			@total_play_time += ms

	reset: (keep_battle = false) ->
		# calculate prestige bonuses (grants are capped so the legacy
		# level-up loops cannot hang on astronomic totals)
		sliggoo.gain_exp Math.min(@total_bloons / 1e12, 1e12)
		goodra.gain_exp Math.min(bloon.exp / 1e4, 1e6)

		# Sliggoo gives a GPS multiplier boost.
		@sliggoo_gpsmult = 1.0 + 0.1 * (sliggoo.level)
		# Goodra raises the level cap.
		bloon.level_cap = 1000 + (goodra.level)

		@bloons = 0
		@bloons_comp = 0
		@total_bloons = 0
		@total_bloons_comp = 0
		# @total_total_bloons is untouched.

		bloon.exp = 0
		bloon.level = 1
		bloon.next_lv_exp = 100
		bloon.lv_total_exp = 0

		# prestige must not keep active shiny buffs around
		@raindance_mult = 1.0
		@frenzy_clickmult = 1.0
		@frenzy_expmult = 1.0
		shiny_bloon.cancel_effects()

		@game_started = false
		@play_time = 0

		@clicks = 0
		for generator in generators
			generator.count = 0
			generator.cost = generator.buy_cost_for(0)
			generator.level = 1
			generator.lvup_cost = generator.base_cost * 100
			generator.upgrades = []

		for name, item of items
			item.bought = false
			item.locked = true

		battle.reset_progress() unless keep_battle
		recalc()
		update_all_numbers()
		regenerate_tooltips()

# DEBUG: expose basedata to access variables.

@basedata = basedata

settings =
	audio: true
	music: true
	number_format: "full"

@settings = settings
