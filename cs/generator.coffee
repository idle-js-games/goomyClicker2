gens = {}
generators = []

class Generator

	# Hard bounds for level and count. Beyond these the cost and production
	# formulas overflow a double (1.3^(L-1) is Infinity past L=2706, 1.15^n past
	# n=5078), which corrupts the economy and makes the save unloadable, so both
	# the load path and the live level-up/purchase path clamp against them.
	@MAX_LEVEL: 999999
	@MAX_COUNT: 1e21

	constructor: (name) ->
		@name = name
		@display_name = name
		@description = ""
		@image = name
		@legacy_names = []

		@base_gps = 0.0
		@premult_gps = 0.0
		@gps = 0.0

		@level = 1
		@level_mult = 1.0

		@base_cost = 15
		@cost = @base_cost
		@count = 0

		# Purchase cost curve. Each building/monkey can set its own balance
		# with set_cost(). When nothing is customised the fallback formula is
		# a 15% compound per owned unit, i.e.
		#   cost(n) = base_cost * (1 + cost_rate) ^ n
		@cost_rate = 0.15
		@cost_fn = null

		@lvup_cost = @base_cost * 100

		gens[name] = this
		generators.push(this)

	buy: (n) ->
		bought = 0
		for i in [0...n]
			break if @count >= Generator.MAX_COUNT
			if basedata.balance() < @cost
				recalc()
				return bought
			basedata.spend(@cost)
			@count += 1
			@cost = @buy_cost_for(@count)
			bought += 1
		recalc()
		play_sound("buy") if bought > 0
		return bought

	sell: (n) ->
		sold = 0
		for i in [0...n]
			if @count <= 0
				recalc()
				return sold
			@count -= 1
			@cost = @buy_cost_for(@count)
			basedata.earn(@cost * 0.25)
			sold += 1
		recalc()
		play_sound("buy") if sold > 0
		return sold

	# total cost of buying n more units from the current count
	bulk_cost: (n) ->
		total = 0
		for i in [0...n]
			total += @buy_cost_for(@count + i)
		total

	# total refund for selling n units (25% of each sold unit's price)
	bulk_sell_value: (n) ->
		total = 0
		for i in [0...n]
			break if @count - i <= 0
			total += Math.max(0, Math.floor(@buy_cost_for(@count - 1 - i) * 0.25))
		total

	# Purchase cost of the next unit (n = owned count). Fallbacks guarantee a
	# sane finite cost even with broken custom values.
	buy_cost_for: (n) ->
		n = 0 unless isFinite(n)
		n = Math.max(0, Math.floor(n))
		base = if isFinite(@base_cost) && @base_cost > 0 then @base_cost else 15
		cost = if @cost_fn then @cost_fn.call(this, n) else NaN
		cost = base * Math.pow(1 + @cost_rate, n) unless isFinite(cost) && cost > 0
		cost = base * Math.pow(1.15, n) unless isFinite(cost) && cost > 0
		clamp_value(Math.max(1, Math.round(cost)))

	# Per-building/monkey purchase cost balance. All fields optional:
	#   rate:    compound growth per owned unit as a fraction (default 0.15)
	#   cost_f:  full custom formula, (n) -> cost, overriding the above
	set_cost: (options = {}) ->
		@cost_rate = options.rate if isFinite(options.rate) && options.rate >= 0
		@cost_fn = options.cost_f if typeof options.cost_f is "function"
		@cost = @buy_cost_for(@count)
		@cost

	levelup: () ->
		return false if @level >= Generator.MAX_LEVEL
		if basedata.balance() < @lvup_cost
			return false
		basedata.spend(@lvup_cost)
		@level += 1
		@lvup_cost = clamp_value(@base_cost * 100 * Math.pow(1.35, @level - 1))
		recalc()
		play_sound("upgrade")
		return true

	set_base_cost: (cost) ->
		@base_cost = cost
		@lvup_cost = @base_cost * 100

	set_theme: (display_name, description, image, legacy_names = []) ->
		@display_name = display_name
		@description = description
		@image = image
		@legacy_names = legacy_names
		for legacy_name in legacy_names
			gens[legacy_name] = this


# actual generator data

cursor = new Generator("cursor")
cursor.base_gps = 0.2
cursor.set_base_cost(15)
cursor.set_theme("Cursor", "A helping cursor that pops a tiny trickle of Bloons.", "cursor")
# repl. time: 100 s

monkey = new Generator("monkey")
monkey.base_gps = 1.0
monkey.set_base_cost(100)
monkey.set_theme("Dart Monkey", "A lil' Dart Monkey who is trained to pop and capture Bloons.", "Monkeys/monkey")
# repl. time: 100 s

tackshooter = new Generator("tackshooter")
tackshooter.base_gps = 5.0
tackshooter.set_base_cost(500)
tackshooter.set_theme("Tack Shooter", "A tower which shoots eight tacks in adjacent volleys to pop numerous Bloons.", "Monkeys/TackShooter", ["daycare"])
# repl. time: 120 s

snipermonkey = new Generator("snipermonkey")
snipermonkey.base_gps = 20.0
snipermonkey.set_base_cost(2500)
snipermonkey.set_theme("Sniper Monkey", "A sniper monkey that can snipe bloons anywhere even if they try to attack.", "Monkeys/SniperMonkey", ["reserve"])
# repl. time: 150 s

bombshooter = new Generator("bombshooter")
bombshooter.base_gps = 80.0
bombshooter.set_base_cost(15000)
bombshooter.set_theme("Bomb Shooter", "A cannon which shoots bombs that detonate on contact, destroying Bloon layers open.", "Monkeys/BombShooter", ["farm"])
# repl. time: 200 s

boomerangthrower = new Generator("boomerangthrower")
boomerangthrower.base_gps = 250.0
boomerangthrower.set_base_cost(50000)
boomerangthrower.set_theme("Boomerang Thrower", "A jungle monkey who throws curving boomerangs that pop any Bloons they touch.", "Monkeys/BoomerangThrower", ["fountain"])
# repl. time: 280 s

gluegunner = new Generator("gluegunner")
gluegunner.base_gps = 1000.0
gluegunner.set_base_cost(350000)
gluegunner.set_theme("Glue Gunner", "A monkey who glues Bloons in place, then corrodes their layers with ease.", "Monkeys/GlueGunner", ["cave"])
# repl. time: 400 s

icetower = new Generator("icetower")
icetower.base_gps = 4000.0
icetower.set_base_cost(2000000)
icetower.set_theme("Ice Tower", "A monkey with the powers of ice, stalling Bloons in freezing blocks.", "Monkeys/IceTower", ["trench"])
# repl. time: 600 s

ninjamonkey = new Generator("ninjamonkey")
ninjamonkey.base_gps = 18000
ninjamonkey.set_base_cost(18000000)
ninjamonkey.set_theme("Ninja Monkey", "A ninja trained to assassinate Bloons with shurikens and advanced Camo detection.", "Monkeys/NinjaMonkey", ["arceus"])
# repl. time: 1111 s

monkeybuccaneer = new Generator("monkeybuccaneer")
monkeybuccaneer.base_gps = 75000
monkeybuccaneer.set_base_cost(100000000)
monkeybuccaneer.set_theme("Monkey Buccaneer", "A boat monkey ready to plunder Bloons with cannons, darts, and piracy.", "Monkeys/MonkeyBuccaneer", ["rngabuser"])
# repl. time: 1024 s

monkeyapprentice = new Generator("monkeyapprentice")
monkeyapprentice.base_gps = 275000
monkeyapprentice.set_base_cost(1000000000)
monkeyapprentice.set_theme("Monkey Apprentice", "A wizard monkey whose fire and power magic bewitch and destroy Bloons.", "Monkeys/MonkeyApprentice", ["cloninglab"])
# repl. time: 1260 s

monkeysub = new Generator("monkeysub")
monkeysub.base_gps = 1350000
monkeysub.set_base_cost(15000000000)
monkeysub.set_theme("Monkey Sub", "A submarine monkey that fires homing barbed torpedarts at Bloons.", "Monkeys/MonkeySub", ["church"])
# repl. time: 1600 s

monkeyace = new Generator("monkeyace")
monkeyace.base_gps = 86500000
monkeyace.set_base_cost(300000000000)
monkeyace.set_theme("Monkey Ace", "A monkey pilot who throws out powerful dart volleys from above.", "Monkeys/MonkeyAce", ["gcminer"])
# repl. time: 32768 s

spikefactory = new Generator("spikefactory")
spikefactory.base_gps = 750000000
spikefactory.set_base_cost(5000000000000)
spikefactory.set_theme("Spike Factory", "A mechanical tower that lays spikes to shred Bloons that pass through.", "Monkeys/SpikeFactory", ["photoncollider"])
# repl. time: 86400 s

monkeyengineer = new Generator("monkeyengineer")
monkeyengineer.base_gps = 40000000000
monkeyengineer.set_base_cost(30e15)
monkeyengineer.set_theme("Monkey Engineer", "An ingenious monkey who invents sentry turrets and attacks with a nail gun.", "Monkeys/MonkeyEngineer")

supermonkey = new Generator("supermonkey")
supermonkey.base_gps = 800000000000
supermonkey.set_base_cost(860e15)
supermonkey.set_theme("Super Monkey", "A powerful monkey who throws darts hypersonically fast to destroy MOAB-class Bloons.", "Monkeys/SuperMonkey")

# --- Per-tower purchase cost balance -------------------------------------
# set_cost() is customisable for each building/monkey. Anything left unset
# here falls back to the 15% compound formula (see Generator above).
cursor.set_cost(rate: 0.10)                         # starter tower: gentle curve
supermonkey.set_cost(rate: 0.20)                    # endgame tower: premium curve

# create a list of the above generators
ngens = [tackshooter, snipermonkey, bombshooter, boomerangthrower, gluegunner, icetower, ninjamonkey, monkeybuccaneer, monkeyapprentice, monkeysub, monkeyace, spikefactory, monkeyengineer, supermonkey]

# create a dictionary by name so they're more easily searchable
for gen in generators
	gen.cost = gen.buy_cost_for(gen.count)
