###

Shiny Bloon effects

Effect             Prob.     Description
-------------      ------    -----------
Bloon Bonus        60.00%    Give a huge bonus of Bloons.
Rain Dance         33.50%    Gives both clicking and GpS a x12 boost for 70.4 seconds.
Click Frenzy        5.00%    Gives clicking a x704 GpC boost for 7.04 seconds.
Click EXP Frenzy    0.95%    Gives clicking a x10 EXP/click boost for 20 seconds.
Level Up            0.45%    Levels the Bloon up once.
                    0.10%

###

init_cooldown_time = 200000

shiny_bloon =

	enabled: false
	appeared: false
	opacity: 0
	x: 0
	y: 0
	effect: "none" # one of "bloons", "raindance", "clickmult", "levelup"

	time_left: 0  # for timed effects.
	cooldown_time: init_cooldown_time  # for cooldown time.

	clicks: 0
	total_clicks: 0

	update: (ms) ->
		if not @enabled
			@enabled = true  # Prevent a shiny Bloon from "always" appearing upon loading a new window due to the long wait time.
		else if @time_left > 0
			@time_left -= ms
			if @time_left <= 0
				# cancel out the initial effect.
				if @effect == "raindance"
					basedata.raindance_mult = 1.0
					$("#shiny_bloon_rain_dance").hide()
					recalc()
				if @effect == "clickmult"
					basedata.frenzy_clickmult = 1.0
					$("#shiny_bloon_click_frenzy").hide()
					recalc()
				if @effect == "clickexpfrenzy"
					basedata.frenzy_expmult = 1.0
					$("#shiny_bloon_click_exp_frenzy").hide()
					recalc()
		else if @appeared
			if @opacity < 1
				@opacity = Math.min(1, @opacity + ms / 2000)
				$("#shiny_bloon").css({opacity: @opacity})
		else # if yet to appear
			if @cooldown_time > 0
				@cooldown_time -= ms
			else if Math.random() > Math.pow(0.995, ms / 1000)
				@appeared = true
				@x = Math.random() * ($(window).width() - $("#shiny_bloon").width())
				@y = Math.random() * ($(window).height() - $("#shiny_bloon").height())

				spinner = Math.random()

				if spinner < 0.6
					@effect = "bloons"
				else if spinner < 0.935
					@effect = "raindance"
				else if spinner < 0.985
					@effect = "clickmult"
				else if spinner < 0.9945
					@effect = "clickexpfrenzy"
				else if spinner < 0.999
					@effect = "levelup"
				else
					@effect = "bloons"

				$("#shiny_bloon").show()
				$("#shiny_bloon").css({left: @x, top: @y, opacity: 0})

				$("#shiny_bloon").off("click.gc2shiny").on("click.gc2shiny", (e) => @click e.pageX, e.pageY)

	click: (x, y) ->
		$("#shiny_bloon").off("click.gc2shiny")
		$("#shiny_bloon").hide()
		@appeared = false
		@opacity = 0
		basedata.clicks += 1
		basedata.total_clicks += 1
		@cooldown_time = init_cooldown_time
		if @effect == "bloons"
			# award = 120 seconds of Bloon production + 200 clicks worth of Bloons
			gain = clamp_value(basedata.gps * 120 + basedata.gpc * 200)
			shiny_plus_marker = new PlusMarker("Bonus! +#{reprnum(Math.floor(gain), "long")} Bloons!", x, y, 3000)
			basedata.earn(gain)
			return gain
		else if @effect == "raindance"
			@time_left = 70400
			basedata.raindance_mult = 12.0
			recalc()
			$("#shiny_bloon_rain_dance").show()
			shiny_plus_marker = new PlusMarker("Rain Dance! Production x12 for 70.4 seconds!", x, y, 3000)
		else if @effect == "clickmult"
			@time_left = 7040
			basedata.frenzy_clickmult = 704.0
			recalc()
			$("#shiny_bloon_click_frenzy").show()
			shiny_plus_marker = new PlusMarker("Click Frenzy! Clicking x704 for 7.04 seconds!", x, y, 3000)
		else if @effect == "clickexpfrenzy"
			@time_left = 20000
			basedata.frenzy_expmult = 10.0
			recalc()
			$("#shiny_bloon_click_exp_frenzy").show()
			shiny_plus_marker = new PlusMarker("EXP Frenzy! Clicking gives x10 EXP for 20 seconds!", x, y, 3000)
		else if @effect == "levelup"
			if bloon.level < bloon.level_cap
				do bloon.level_up
			shiny_plus_marker = new PlusMarker("Level Up! The Bloon is now level #{bloon.level}!", x, y, 3000)

	# wipe any active timed effect (used by prestige/reset)
	cancel_effects: ->
		@time_left = 0
		@effect = "none"
		$("#shiny_bloon_rain_dance").hide()
		$("#shiny_bloon_click_frenzy").hide()
		$("#shiny_bloon_click_exp_frenzy").hide()


@shiny_bloon = shiny_bloon
@click_on_shiny_bloon = shiny_bloon.click
