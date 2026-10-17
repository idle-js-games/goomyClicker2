# Save fields are validated while importing: a corrupt or hand-edited save
# must never poison the running game with NaN (NaN comparisons always fail, so
# a single NaN field used to brick purchases and then get re-saved forever).
parse_num = (value, fallback = 0) ->
	n = parseFloat(value)
	if isFinite(n) then n else fallback

parse_int = (value, fallback = 0) ->
	n = parseInt(value, 10)
	if isFinite(n) then n else fallback

# clamp a loaded number into a finite range. A value that is already Infinity
# or NaN (e.g. a count so large that parseInt overflows) falls back to the
# minimum instead of being admitted into the simulation.
clamp_finite = (value, min, max, fallback = min) ->
	n = parseFloat(value)
	return fallback unless isFinite(n)
	Math.min(max, Math.max(min, n))

# offline progress granted when loading a save is capped at one day
MAX_OFFLINE_MS = 24 * 60 * 60 * 1000

# mirror the bounds the Generator class enforces on the live path so the
# import path cannot admit a value the rest of the game would reject.
MAX_GENERATOR_COUNT = Generator.MAX_COUNT
MAX_GENERATOR_LEVEL = Generator.MAX_LEVEL
MAX_ETERNAL_STAGE = 999
# Bloon/sliggoo/goodra exp ceilings. Bloon exp feeds a loop that runs a DOM
# rewrite per level, so an imported Infinity there would freeze the tab.
MAX_EXP = 1e15

number_format_load_codes = {
	"0": "full"
	"1": "small"
	"2": "scientific"
	"3": "engineering"
}

sanitize_number_format = (format) ->
	number_format_load_codes[format] || (if format in ["full", "small", "scientific", "engineering"] then format else "full")

load_save_from_local_storage = () ->

	if window.localStorage.hasOwnProperty("gc2.savefile") and window.localStorage["gc2.savefile"] != ""

		save_data = null
		try
			save_data = import_save(b64_to_sstr(window.localStorage["gc2.savefile"]))
		catch error
			# never destroy the stored save: quarantine the unparseable value
			# so it can be recovered, then start a fresh run
			console.warn("Could not load local save; quarantining invalid save data.", error)
			window.localStorage["gc2.savefile.corrupt"] = window.localStorage["gc2.savefile"]
			window.localStorage["gc2.savefile"] = ""
			return
		return unless save_data

		save_ms = save_data["save_time"].getTime()
		save_ms = new Date().getTime() unless isFinite(save_ms)

		if save_data["play_time"] != -1
			basedata.game_started = true
			basedata.play_time = save_data["play_time"]

		basedata.total_play_time = save_data["total_play_time"]
		basedata.bloons = save_data["bloons"]
		basedata.bloons_comp = 0
		basedata.total_bloons_comp = 0
		basedata.total_total_bloons_comp = 0
		basedata.total_bloons = save_data["total_bloons"]
		basedata.total_total_bloons = save_data["total_total_bloons"]
		basedata.clicks = save_data["clicks"]
		basedata.total_clicks = save_data["total_clicks"]

		# reset progression state first so loading is idempotent: gain_exp is
		# additive and would otherwise double exp when re-loading a save
		bloon.exp = 0
		bloon.level = 1
		bloon.next_lv_exp = 100
		bloon.lv_total_exp = 0
		sliggoo.exp = 0
		sliggoo.level = 0
		sliggoo.next_lv_exp = 25
		sliggoo.lv_total_exp = 0
		goodra.exp = 0
		goodra.level = 0
		goodra.next_lv_exp = 1000
		goodra.lv_total_exp = 0

		bloon.gain_exp(save_data["bloon_exp"])
		sliggoo.gain_exp(save_data["sliggoo_exp"])
		goodra.gain_exp(save_data["goodra_exp"])

		basedata.prestige_count = Math.max(0, Math.min(15, parse_int(save_data["prestige_count"], 0)))
		basedata.prestige_mult = Math.pow(2, basedata.prestige_count)

		basedata.sliggoo_gpsmult = clamp_value(1.0 + 0.1 * (sliggoo.level))
		bloon.level_cap = Math.min(bloon.MAX_BLOON_LEVEL, 1000 + (goodra.level))

		for generator in generators
			if save_data.generators[generator.name]
				generator.count = clamp_finite(save_data.generators[generator.name].count, 0, MAX_GENERATOR_COUNT)
				generator.level = clamp_finite(save_data.generators[generator.name].level, 1, MAX_GENERATOR_LEVEL, 1)
			else
				generator.count = 0
				generator.level = 1
			generator.cost = generator.buy_cost_for(generator.count)
			generator.lvup_cost = clamp_value(generator.base_cost * 100 * Math.pow(1.35, generator.level - 1))

		recalc()

		# re-create the upgrade UI for upgrades restored as unlocked: it is only
		# generated at unlock time, so without this they vanish from the shop
		for item in itemlist when !item.locked
			ensure_item_dom(item)

		# grant offline production explicitly and capped: the game loop itself
		# clamps every tick to MAX_TICK_MS, so this is applied exactly once
		offline_ms = Math.min(Math.max(0, new Date().getTime() - save_ms), MAX_OFFLINE_MS)
		if offline_ms > 0 && isFinite(basedata.gps) && isFinite(basedata.expps)
			basedata.earn(clamp_value(basedata.gps * (offline_ms / 1000)))
			bloon.gain_exp(clamp_value(basedata.expps * (offline_ms / 1000)))

		last_update_time.setTime(new Date().getTime())

		$("#settings_audio").prop("checked", settings.audio)
		$("#settings_music").prop("checked", settings.music)
		$("#settings_number_format").val(settings.number_format)
		battle.render()
		update_all_numbers()


import_save = (str) ->

	version = str.split("||", 1)[0]  # first instance of a number

	if version == SAVE_FORMAT_VERSION
		return _import_save_0_10(str)
	else if version == "0.12"
		return _import_save_0_10(str)
	else if version == "0.11"
		return _import_save_0_10(str)
	else if version == "0.10"
		return _import_save_0_10(str)
	else if version == "0.05"
		return _import_save_0_05(str)
	else
		return null




##########
# actual import methods
##########





# save file version 0.10
_import_save_0_10 = (str) ->

	save = {}

	data = str.split("||")

	save_time = new Date()
	save_time.setTime(parse_int(data[1], new Date().getTime()))
	save["save_time"] = save_time

	d02_basedata = data[2].split("|")
	save["play_time"] = clamp_finite(d02_basedata[0], -1, MAX_VALUE, -1)
	save["total_play_time"] = clamp_finite(d02_basedata[1], 0, MAX_VALUE)
	save["bloons"] = clamp_finite(d02_basedata[2], 0, MAX_VALUE)
	save["total_bloons"] = clamp_finite(d02_basedata[3], 0, MAX_VALUE)
	save["total_total_bloons"] = clamp_finite(d02_basedata[4], 0, MAX_VALUE)
	save["clicks"] = clamp_finite(d02_basedata[5], 0, MAX_VALUE)
	save["total_clicks"] = clamp_finite(d02_basedata[6], 0, MAX_VALUE)

	d03_bloonstats = data[3].split("|")
	save["bloon_exp"] = clamp_finite(d03_bloonstats[0], 0, MAX_EXP)
	save["sliggoo_exp"] = clamp_finite(d03_bloonstats[1], 0, MAX_EXP)
	save["goodra_exp"] = clamp_finite(d03_bloonstats[2], 0, MAX_EXP)

	generator_names = [
		"cursor",
		"monkey",
		"tackshooter",
		"snipermonkey",
		"bombshooter",
		"boomerangthrower",
		"gluegunner",
		"icetower",
		"ninjamonkey",
		"monkeybuccaneer",
		"monkeyapprentice",
		"monkeysub",
		"monkeyace",
		"spikefactory",
		"monkeyengineer",
		"supermonkey"
	]
	legacy_generator_names = [
		"cursor",
		"monkey",
		"daycare",
		"reserve",
		"farm",
		"fountain",
		"cave",
		"trench",
		"arceus",
		"rngabuser",
		"cloninglab",
		"church",
		"gcminer",
		"photoncollider",
		"monkeyengineer",
		"supermonkey"
	]

	gen_data = {}
	d04_generators = data[4].split("|")
	for i in [0..Math.min(generator_names.length, d04_generators.length)-1]
		datum = d04_generators[i].split(",")
		gen_data[generator_names[i]] = {
			count: Math.max(0, parse_num(datum[0], 0))
			level: Math.max(1, parse_int(datum[1], 1))
		}
		if legacy_generator_names[i] != generator_names[i]
			gen_data[legacy_generator_names[i]] = gen_data[generator_names[i]]
	save["generators"] = gen_data

	d05_upgrades = data[5].split("|")
	d05_upgrades_unlocked = sstr_to_bitfield(d05_upgrades[0])
	d05_upgrades_bought = sstr_to_bitfield(d05_upgrades[1])
	for id in [1..250]
		if item_ids[id]
			if d05_upgrades_unlocked[id-1] == "1"
				item_ids[id].locked = false
				if d05_upgrades_bought[id-1] == "1"
					item_ids[id].bought = true

	if data[6]
		d07_settings = data[6].split("|")
		settings.audio = d07_settings[0] != "0"
		settings.music = d07_settings[1] != "0"
		settings.number_format = sanitize_number_format(d07_settings[2] || "0")
		audio.refresh_music()
	if data[7]
		d08_battle = data[7].split("|")
		saved_defeated = Math.max(0, parseInt(d08_battle[0]) || 0)
		saved_eternal_stage = parseInt(d08_battle[2])
		battle.current_index = Math.min(saved_defeated, battle.bloons.length)
		battle.eternal_stage = if isFinite(saved_eternal_stage) then clamp_finite(saved_eternal_stage, 0, MAX_ETERNAL_STAGE) else clamp_finite(saved_defeated - battle.bloons.length, 0, MAX_ETERNAL_STAGE)
		battle.defeated = battle.current_index + battle.eternal_stage
		battle.active = false
		battle.recalculate_rewards()

	save["prestige_count"] = 0
	if data[8]
		d09_prestige = data[8].split("|")
		save["prestige_count"] = Math.max(0, parse_int(d09_prestige[0], 0))

	return save







# save file version 0.05
_import_save_0_05 = (str) ->

	save = {}

	data = str.split("||", 5)

	save_time = new Date()
	save_time.setTime(parse_int(data[1], new Date().getTime()))
	save["save_time"] = save_time

	d02_basedata = data[2].split("|")
	save["play_time"] = clamp_finite(d02_basedata[0], -1, MAX_VALUE, -1)
	save["total_play_time"] = clamp_finite(d02_basedata[1], 0, MAX_VALUE)
	save["bloons"] = clamp_finite(d02_basedata[2], 0, MAX_VALUE)
	save["total_bloons"] = clamp_finite(d02_basedata[3], 0, MAX_VALUE)
	save["total_total_bloons"] = clamp_finite(d02_basedata[4], 0, MAX_VALUE)
	save["clicks"] = clamp_finite(d02_basedata[5], 0, MAX_VALUE)
	save["total_clicks"] = clamp_finite(d02_basedata[6], 0, MAX_VALUE)

	d03_bloonstats = data[3].split("|")
	save["bloon_exp"] = clamp_finite(d03_bloonstats[0], 0, MAX_EXP)
	save["sliggoo_exp"] = clamp_finite(d03_bloonstats[1], 0, MAX_EXP)
	save["goodra_exp"] = clamp_finite(d03_bloonstats[2], 0, MAX_EXP)

	generator_names = [
		"cursor",
		"monkey",
		"tackshooter",
		"snipermonkey",
		"bombshooter",
		"boomerangthrower",
		"gluegunner",
		"icetower",
		"ninjamonkey",
		"monkeybuccaneer",
		"monkeyapprentice",
		"monkeysub",
		"monkeyace",
		"spikefactory",
		"monkeyengineer",
		"supermonkey"
	]
	legacy_generator_names = [
		"cursor",
		"monkey",
		"daycare",
		"reserve",
		"farm",
		"fountain",
		"cave",
		"trench",
		"arceus",
		"rngabuser",
		"cloninglab",
		"church",
		"gcminer",
		"photoncollider",
		"monkeyengineer",
		"supermonkey"
	]

	gen_data = {}
	d04_generators = data[4].split("|")
	for i in [0..Math.min(generator_names.length, d04_generators.length)-1]
		datum = d04_generators[i].split(",")
		gen_data[generator_names[i]] = {
			count: Math.max(0, parse_num(datum[0], 0))
			level: Math.max(1, parse_int(datum[1], 1))
		}
		if legacy_generator_names[i] != generator_names[i]
			gen_data[legacy_generator_names[i]] = gen_data[generator_names[i]]
	save["generators"] = gen_data


	return save
