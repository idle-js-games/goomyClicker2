bloon_image = (fill, stroke = "%238aa4ff") ->
	"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 180 220'><defs><radialGradient id='g' cx='60%25' cy='25%25' r='70%25'><stop offset='0%25' stop-color='%23ffffff' stop-opacity='.75'/><stop offset='40%25' stop-color='#{fill}'/><stop offset='100%25' stop-color='#{fill}' stop-opacity='.82'/></radialGradient></defs><ellipse cx='90' cy='84' rx='68' ry='76' fill='url(%23g)' stroke='#{stroke}' stroke-width='8'/><path d='M78 155h24l-12 40z' fill='#{fill}' stroke='#{stroke}' stroke-width='6' stroke-linejoin='round'/></svg>"

set_image_with_fallback = (selector, sources) ->
	$img = $(selector)
	sources = [sources] unless $.isArray(sources)
	token = new Date().getTime() + Math.random()
	timeout = null
	$img.data("imageToken", token)
	try_source = (index) ->
		return unless $img.data("imageToken") == token
		return if index >= sources.length
		window.clearTimeout(timeout) if timeout
		$img.off(".battleImage")
		timeout = window.setTimeout((-> try_source(index + 1)), 3500)
		$img.one("load.battleImage", -> window.clearTimeout(timeout))
		$img.one("error.battleImage", ->
			window.clearTimeout(timeout)
			try_source(index + 1)
		)
		$img.attr("src", sources[index])
	try_source(0)

ETERNAL_BLOON_IMAGE = asset_url("Bloons/EternalBloon.svg")
ETERNAL_BLOON_FALLBACK = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 240 260'><defs><radialGradient id='g' cx='58%25' cy='24%25' r='72%25'><stop offset='0%25' stop-color='%23f8fff3'/><stop offset='20%25' stop-color='%238cff88'/><stop offset='62%25' stop-color='%232cb7ef'/><stop offset='100%25' stop-color='%233d49b7'/></radialGradient><filter id='glow'><feGaussianBlur stdDeviation='5' result='b'/><feMerge><feMergeNode in='b'/><feMergeNode in='SourceGraphic'/></feMerge></filter><linearGradient id='fog' x1='0' x2='1'><stop offset='0%25' stop-color='%2336f8ff' stop-opacity='.25'/><stop offset='50%25' stop-color='%23c9ffff' stop-opacity='.72'/><stop offset='100%25' stop-color='%2336f8ff' stop-opacity='.25'/></linearGradient></defs><rect width='240' height='260' fill='%2325303c'/><path d='M0 174c48-22 72 16 120-5 50-22 82 17 120-5v96H0z' fill='url(%23fog)'/><ellipse cx='120' cy='100' rx='80' ry='86' fill='url(%23g)' stroke='%23f6ff62' stroke-width='9' filter='url(%23glow)'/><circle cx='150' cy='60' r='12' fill='%23f5fff7'/><path d='M56 100c24-37 51-37 64 0 13 37 40 37 64 0M56 100c24 37 51 37 64 0 13-37 40-37 64 0' fill='none' stroke='%23fff765' stroke-width='14' stroke-linecap='round' filter='url(%23glow)'/><path d='M102 181h36l-18 42z' fill='%233cb6e8' stroke='%23f6ff62' stroke-width='7' stroke-linejoin='round'/><g stroke='%233cecff' stroke-width='7' fill='none' opacity='.55'><path d='M10 142c18-28 34-28 52 0 18 28 34 28 52 0'/><path d='M126 142c18-28 34-28 52 0 18 28 34 28 52 0'/></g></svg>"

battle =
	active: false
	timer: 30000
	duration: 30000
	hp: 0
	max_hp: 0
	tap_mult: 1
	bps_mult: 1
	defeated: 0
	current_index: 0
	eternal_stage: 0
	last_battle_image_signature: null
	last_main_image_signature: null
	bloons: [
		{name: "Blue Bloon", hp: 1000, tap_reward: 0.01, bps_reward: 0.005, image: [bloon_asset("BlueBloon"), bloon_image("%233e7bff", "%238aa4ff")]}
		{name: "Green Bloon", hp: 7500, tap_reward: 0.015, bps_reward: 0.0075, image: [bloon_asset("GreenBloon"), bloon_image("%2337d45f", "%2382f59a")]}
		{name: "Yellow Bloon", hp: 50000, tap_reward: 0.02, bps_reward: 0.01, image: [bloon_asset("YellowBloon"), bloon_image("%23ffd83f", "%23fff187")]}
		{name: "Pink Bloon", hp: 350000, tap_reward: 0.025, bps_reward: 0.0125, image: [bloon_asset("PinkBloon"), bloon_image("%23ff5fb7", "%23ff9fd4")]}
		{name: "Black Bloon", hp: 2500000, tap_reward: 0.03, bps_reward: 0.015, image: [bloon_asset("BlackBloon"), bloon_image("%2324242a", "%23757582")]}
		{name: "White Bloon", hp: 15000000, tap_reward: 0.035, bps_reward: 0.0175, image: [bloon_asset("WhiteBloon"), bloon_image("%23f7f7f7", "%23c9d8ff")]}
		{name: "Lead Bloon", hp: 100000000, tap_reward: 0.04, bps_reward: 0.02, image: [asset_url("Bloons/LeadBloon.svg"), bloon_image("%23838383", "%23c8c8c8")]}
		{name: "Zebra Bloon", hp: 750000000, tap_reward: 0.045, bps_reward: 0.0225, image: [asset_url("Bloons/ZebraBloon.svg"), bloon_image("%23ffffff", "%23161616")]}
		{name: "Rainbow Bloon", hp: 5000000000, tap_reward: 0.05, bps_reward: 0.025, image: [asset_url("Bloons/RainbowBloon.svg"), bloon_image("%23ff4646", "%23864cff")]}
		{name: "Ceramic Bloon", hp: 40000000000, tap_reward: 0.06, bps_reward: 0.03, image: [asset_url("Bloons/CeramicBloon.svg"), bloon_image("%23c7803c", "%23ffd17d")]}
		{name: "MOAB", hp: 250000000000, tap_reward: 0.075, bps_reward: 0.04, image: asset_url("Bloons/MOAB.svg")}
		{name: "BFB", hp: 2500000000000, tap_reward: 0.1, bps_reward: 0.055, image: asset_url("Bloons/BFB.svg")}
		{name: "ZOMG", hp: 25000000000000, tap_reward: 0.13, bps_reward: 0.07, image: asset_url("Bloons/ZOMG.svg")}
		{name: "B.A.D", hp: 250000000000000, tap_reward: 0.18, bps_reward: 0.1, image: asset_url("Bloons/BAD.svg")}
	]
	eternal_base_hp: 250000000000000 * 21
	eternal_hp_scale: 7.5
	eternal_tap_reward: 0.10
	eternal_bps_reward: 0.05
	MAX_ETERNAL_STAGE: 999
	MAX_BATTLE_TROPHIES: 40
	previous_bloon: ->
		return null if @defeated <= 0
		if @eternal_stage > 0 && @current_index >= @bloons.length
			stage = @eternal_stage
			return {
				name: "Eternal Bloon (Tier #{stage})"
				image: [ETERNAL_BLOON_IMAGE, ETERNAL_BLOON_FALLBACK]
			}
		@bloons[Math.max(0, Math.min(@current_index - 1, @bloons.length - 1))]
	current_bloon: ->
		if @current_index >= @bloons.length
			stage = @eternal_stage + 1
			return {
				name: "Eternal Bloon (Tier #{stage})"
				hp: clamp_value(@eternal_base_hp * Math.pow(@eternal_hp_scale, @eternal_stage))
				tap_reward: @eternal_tap_reward + @eternal_stage * 0.01
				bps_reward: @eternal_bps_reward + @eternal_stage * 0.005
				image: [ETERNAL_BLOON_IMAGE, ETERNAL_BLOON_FALLBACK]
				eternal: true
			}
		@bloons[Math.min(@current_index, @bloons.length - 1)]
	reset_progress: ->
		@active = false
		@timer = @duration
		@hp = 0
		@max_hp = 0
		@defeated = 0
		@current_index = 0
		@eternal_stage = 0
		@last_battle_image_signature = null
		@last_main_image_signature = null
		@recalculate_rewards()
		$("#battle_trophies").empty()
		@render_status("Ready for battle.")
		@render()
	recalculate_rewards: ->
		@tap_mult = 1
		@bps_mult = 1
		for i in [0...Math.min(@defeated, @bloons.length)]
			@tap_mult += @bloons[i].tap_reward
			@bps_mult += @bloons[i].bps_reward
		if @eternal_stage > 0
			for stage in [1..@eternal_stage]
				@tap_mult += @eternal_tap_reward + (stage - 1) * 0.01
				@bps_mult += @eternal_bps_reward + (stage - 1) * 0.005
	start: ->
		unless $("#battle_tab").hasClass("active") && $("#battle_start").is(":visible")
			return @render_status("Open the Battle tab before starting a boss fight.")
		if @active
			return @render_status("Already fighting #{@current_bloon().name}!")
		bloon = @current_bloon()
		@active = true
		@timer = @duration
		@max_hp = bloon.hp
		@hp = @max_hp
		@last_battle_image_signature = null
		@last_main_image_signature = null
		play_sound("upgrade")
		@render_status("Fight started: #{bloon.name}. Pop it before time runs out. Your BpS is channeled into damage while fighting.")
		@render()
	tap: ->
		return unless @active
		play_sound("tap")
		@damage(Math.max(1, basedata.damage_gpc))
	damage: (n, render_after = true) ->
		return unless @active
		return unless isFinite(n) && n > 0
		@hp -= n
		if @hp <= 0
			@win()
		else if render_after
			@render_values()
	win: ->
		bloon = @current_bloon()
		name = bloon.name
		@active = false
		@defeated += 1
		if bloon.eternal
			@eternal_stage = Math.min(@eternal_stage + 1, @MAX_ETERNAL_STAGE)
		else
			@current_index = Math.min(@current_index + 1, @bloons.length)
		@tap_mult += bloon.tap_reward
		@bps_mult += bloon.bps_reward
		next_bloon = @current_bloon()
		@timer = @duration
		@max_hp = next_bloon.hp
		@hp = @max_hp
		play_sound("win")
		$("#battle_trophies").append("<div class='battle-trophy'>#{name}<br/>+#{(bloon.tap_reward * 100).toFixed(1)}% Tap, +#{(bloon.bps_reward * 100).toFixed(1)}% BPS</div>")
		$("#battle_trophies .battle-trophy").slice(0, -@MAX_BATTLE_TROPHIES).remove() if $("#battle_trophies .battle-trophy").length > @MAX_BATTLE_TROPHIES
		refresh_scrollers()
		@last_battle_image_signature = null
		@last_main_image_signature = null
		@render_status("Victory! #{name} defeated. Next up: #{@current_bloon().name}.")
		@render()
		recalc()
	lose: ->
		@active = false
		@timer = 0
		@render_status("Time up! #{@current_bloon().name} escaped. Build up your BPS and re-engage when ready.")
		@render_values()
	retreat: ->
		return unless @active
		bloon = @current_bloon()
		@active = false
		@timer = 0
		@hp = @max_hp
		play_sound("tap")
		@render_status("Retreated! #{bloon.name} recovered to full HP. Build up your BPS and re-engage when ready.")
		@render_values()
	update: (ms) ->
		return unless @active
		return unless isFinite(ms) && ms > 0
		if @resume_guard
			@resume_guard = false
			return
		return if document.hidden
		@timer = Math.max(0, @timer - ms)
		if @timer <= 0
			return @lose()
		passive_damage = basedata.damage_gps * ms / 1000
		@damage(passive_damage, false) if passive_damage > 0
		@render_values() if @active
	on_visibility: ->
		return if document.hidden
		@resume_guard = true if @active
	render_status: (message) -> $("#battle_status").html(message)
	image_signature: (sources) ->
		if $.isArray(sources) then sources.join("|") else sources
	render_images: (bloon, sources) ->
		battle_signature = @image_signature(sources)
		if battle_signature != @last_battle_image_signature
			set_image_with_fallback("#battle_bloon_img", sources)
			@last_battle_image_signature = battle_signature
		previous = @previous_bloon()
		# no bloons slain yet: show a Red Bloon instead of the placeholder image
		main_sources = if previous then previous.image else [bloon_asset("RedBloon"), bloon_image("%23e03535", "%23ff8a8a")]
		main_signature = @image_signature(main_sources)
		if main_signature != @last_main_image_signature
			set_image_with_fallback("#great_bloon", main_sources)
			@last_main_image_signature = main_signature
	render_values: ->
		bloon = @current_bloon()
		hp_value = if @active then @hp else bloon.hp
		max_hp_value = if @active then @max_hp else bloon.hp
		$("#battle_timer").html((Math.max(0, @timer) / 1000).toFixed(1) + "s")
		$("#battle_hp").attr("max", max_hp_value)
		$("#battle_hp").attr("value", Math.max(0, hp_value))
		$("#battle_hp_value").html(reprnum(Math.ceil(Math.max(0, hp_value))) + " / " + reprnum(max_hp_value) + " HP")
		$("#battle_tap").prop("disabled", !@active)
		$("#battle_retreat").prop("disabled", !@active)
	render: ->
		bloon = @current_bloon()
		sources = bloon.image
		$("#battle_target").html(bloon.name)
		@render_images(bloon, sources)
		@render_values()

@battle = battle

$(document).on "visibilitychange.gc2", -> battle.on_visibility()
