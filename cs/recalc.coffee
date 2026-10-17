recalc = ->

	recalc_gps()
	recalc_gpc()
	update_all_numbers()

recalc_gps = ->

	# account for base gps upgrades first.
	gens["monkey"].base_gps = 1.0
	if items["ball01"].bought
		gens["monkey"].base_gps += 0.5
	if items["ball02"].bought
		gens["monkey"].base_gps += 1.0
	if items["ball99"].bought
		gens["monkey"].base_gps += 100.0

	# global production multipliers shared by every building
	global_mult = clamp_value(basedata.sliggoo_gpsmult * basedata.raindance_mult * battle.bps_mult)

	for gen in generators
		# reset the variables for calculation
		gen.level_mult = clamp_value(Math.pow(1.3, gen.level - 1))
		gen.gps = clamp_value(gen.base_gps * gen.level_mult)

	# tiered generator upgrades
	for item in itemlist
		if item.bought && item.generator_name && gens[item.generator_name]
			gens[item.generator_name].gps = clamp_value(gens[item.generator_name].gps * item.bps_mult)

	# the per-building BPS shown in tooltips must carry every multiplier,
	# prestige included, so it agrees with the total the HUD reports
	for gen in generators
		gen.gps = clamp_value(gen.gps * global_mult * basedata.prestige_mult)

	# each cursor level adds +0.1 EXP/s per cursor on top of its 0.2 base
	basedata.expps = clamp_value((0.2 + 0.1 * (gens["cursor"].level - 1)) * gens["cursor"].count)

	new_gps = 0
	for gen in generators
		new_gps += gen.count * gen.gps

	basedata.gps = clamp_value(new_gps)
	# prestige is an earnings multiplier only; boss fights channel the
	# un-prestiged BPS into damage, so prestige cannot overboost the fight.
	# prestige_mult is a power of two, so the division is exact.
	basedata.damage_gps = clamp_value(new_gps / basedata.prestige_mult)


recalc_gpc = ->

	new_gpc = 0

	new_gpc += bloon.level

	for gen in generators
		if items["gcm1"].bought
			new_gpc += gen.count * (bloon.level - 5) * 0.1
		if items["gcm2"].bought
			new_gpc += gen.count * (bloon.level - 10) * 0.2
		if items["gcm3"].bought
			new_gpc += gen.count * (bloon.level - 20) * 0.5
		if items["gcm4"].bought
			new_gpc += gen.count * (bloon.level - 40) * 2.0
		if items["gcm5"].bought
			new_gpc += gen.count * (bloon.level - 80) * 10.0

	new_gpc *= Math.pow(1.1, gens["cursor"].level - 1)
	new_gpc *= basedata.raindance_mult
	new_gpc *= basedata.frenzy_clickmult
	new_gpc *= battle.tap_mult

	basedata.bpc = clamp_value(new_gpc)
	basedata.gpc = clamp_value(new_gpc * basedata.prestige_mult)
	# same rule as BPS: boss taps use the un-prestiged click value
	basedata.damage_gpc = basedata.bpc
