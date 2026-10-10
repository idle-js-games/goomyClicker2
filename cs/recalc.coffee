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

	for gen in generators
		# reset the variables for calculation
		gen.level_mult = Math.pow(1.3, gen.level - 1)
		gen.gps = gen.base_gps * gen.level_mult

	# tiered generator upgrades
	for item in itemlist
		if item.bought && item.generator_name && gens[item.generator_name]
			gens[item.generator_name].gps *= item.bps_mult

	basedata.expps = 0.2 * gens["cursor"].count

	new_gps = 0
	for gen in generators
		new_gps += gen.count * gen.gps

	new_gps *= basedata.sliggoo_gpsmult
	new_gps *= basedata.prestige_mult
	new_gps *= basedata.raindance_mult
	new_gps *= battle.bps_mult

	basedata.gps = new_gps


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
	new_gpc *= basedata.prestige_mult
	new_gpc *= basedata.raindance_mult
	new_gpc *= basedata.frenzy_clickmult
	new_gpc *= battle.tap_mult

	basedata.gpc = new_gpc
