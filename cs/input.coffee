# --- Hybrid-device input fix -----------------------------------------------
# touche.min.js rewrites jQuery's exact "click" bindings into "touchend" only
# on touch-capable devices, which makes mouse-driven controls dead on hybrid
# hardware (touchscreen laptops, tablets with a mouse). Route plain "click"
# bindings through a namespaced type instead: touche leaves namespaced types
# alone, and browsers fire a normal click for both mouse and touch input.
do ->
	return unless window.jQuery && jQuery.fn.on
	original_on = jQuery.fn.on
	jQuery.fn.on = (types, selector, data, fn) ->
		types = "click.gc2input" if types == "click"
		original_on.call(this, types, selector, data, fn)

generator_image_url = (image) -> asset_url(image)

init_input = ->

	$(".nano").nanoScroller()
	$(document).one("mousedown touchstart keydown", -> audio.unlock())

	# populate the generator pane (idempotent: tiles and their images are built
	# exactly once and never reconstructed)
	for generator in ngens
		continue if $("##{generator.name}").length
		$("#generators").append("<div class='generator' id='#{generator.name}'></div>")
		$("##{generator.name}").append('<div class="generator-info"></div>')
		$("##{generator.name}").css("background-image", "url('#{generator_image_url(generator.image)}')")
		$("##{generator.name} .generator-info").append("<span class='generator-count' id='#{generator.name}_count'></span><br />
			Next: <span class='generator-cost' id='#{generator.name}_cost'>#{reprnum(generator.base_cost, "short")}</span>")

	if $(window).width() >= 1024
		for generator in generators
			$("##{generator.name}").off("click.gc2buy").on("click.gc2buy", ((name) -> (() -> gens[name].buy(1)))(generator.name))
	# if on a mobile platform, clicking on tooltips shouldn't autobuy.

	$("#bloon_container").mousedown (e) ->
		audio.unlock()
		gain = basedata.click()
		play_sound("tap")
		plus_marker = new PlusMarker("+#{reprnum(Math.floor(gain))}", e.clientX - 10 + Math.random() * 20, e.clientY - 10 + Math.random() * 20)

	$("#bloon_container").contextmenu( -> return false)

	$("#bloon_container").mousedown ->
		$("#great_bloon").css("width", "96%")
		$("#great_bloon").css("top", "2%")

	$("#bloon_container").mouseup ->
		$("#great_bloon").css("width", "100%")
		$("#great_bloon").css("top", "0%")

	$("#export_save_button").click ->
		a = export_save()
		$("#export_save").show()
		$("#export_save_string").val(a)
		$("#export_qr_code")[0].getContext("2d").clearRect(0, 0, 200, 200)
		$("#export_qr_code").qrcode({ text: a })

	$(".menu-tab").click ->
		target = $(this).attr("data-tab")
		$(".menu-tab").removeClass("active")
		$(this).addClass("active")
		$(".menu-panel").removeClass("active")
		$("##{target}").addClass("active")

	$("#battle_start").click -> battle.start()
	$("#battle_tap").click -> battle.tap()
	$("#battle_retreat").click -> battle.retreat()

	$("#prestige_now").click ->
		unless basedata.can_prestige()
			return false
		if window.confirm && !window.confirm("Prestige now? Your Bloons, monkeys and upgrades will reset for a permanent x2 global earnings multiplier.")
			return false
		if basedata.prestige()
			$("#prestige_status").html("Prestige complete! Global earnings are now x#{reprnum(basedata.prestige_mult, "short")}.")

	# settings tab
	$("#settings_audio").change ->
		settings.audio = $(this).is(":checked")
		play_sound("tap") if settings.audio
		save_to_local_storage()
	$("#settings_music").change ->
		settings.music = $(this).is(":checked")
		audio.refresh_music()
		save_to_local_storage()
	$("#settings_number_format").change ->
		settings.number_format = $(this).val()
		update_all_numbers()
		battle.render()
		save_to_local_storage()
	$("#settings_save_now").click ->
		save_to_local_storage(true)
		now = new Date()
		$("#settings_save_status").html("Progress saved at " + now.toLocaleTimeString() + ".")

	$("#settings_load_save").click ->
		if window.confirm && !window.confirm("Load the last saved progress? Unsaved progress since the last save will be lost.")
			return false
		window.location.reload()

	$("#settings_reset_progress").click ->
		if window.confirm && !window.confirm("Reset all progress? This cannot be undone.")
			return false
		window.localStorage["gc2.savefile"] = ""
		window.location.reload()

	$("#about_close").click -> $("#about").hide()
	$("#export_close").click -> $("#export_save").hide()
