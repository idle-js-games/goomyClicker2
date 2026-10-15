refresh_scrollers = -> $(".nano").nanoScroller()

destroy_qtip = ($el) ->
	try
		$el.qtip("destroy", true) if $el.data("qtip")
	catch e
		null

# Upgrade (item) UI pieces. ensure_item_dom is idempotent: an item's tile,
# tooltip and widget are created exactly once (never duplicated per prestige)
# and the tile's visibility simply tracks its bought state. The helpers below
# let regenerate_tooltips rebuild the tooltip nodes it wipes from #tooltips.
ensure_item_dom = (item) ->
	created = false
	$tile = $("##{item.name}")
	unless $tile.length
		$("#items").append("
			<div class='item' id='#{item.name}'>
				#{item.display_name || item.name}
			</div>
		")
		$tile = $("##{item.name}")
		$tile.off("click.gc2item").on("click.gc2item", ((name) -> ( ->
			if items[name].buy()
				$("##{name}").hide().data("itemHidden", true)
		))(item.name))
		created = true
	unless $("##{item.name}_tooltip").length
		create_item_tooltip_content(item)
		init_item_qtip(item)
		created = true
	want_hidden = !!item.bought
	if $tile.data("itemHidden") != want_hidden
		$tile.data("itemHidden", want_hidden)
		if want_hidden then $tile.hide() else $tile.show()
	if created
		clear_hud_cache()
		refresh_scrollers()

create_item_tooltip_content = (item) ->
	$("##{item.name}_tooltip").remove()
	$("#tooltips").append("<div class='item-tooltip' id='#{item.name}_tooltip'></div>")
	$("##{item.name}_tooltip").append(
		"<p id='#{item.name}_description'>" + (langs[lang]["#{item.name}_description"] || item.description) + "</p>" + "
		<br />
		Cost: <span class='tooltip-gps' id='#{item.name}_tooltip_cost'></span> Bloons
		<hr />" +
		"<span id='#{item.name}_flavourtext'>" + (langs[lang]["#{item.name}_caption"] || item.caption) + "</span>"
	)
	$("##{item.name}_tooltip_cost").html(reprnum(Math.floor(item.cost), "long"))

init_item_qtip = (item) ->
	$tile = $("##{item.name}")
	return unless $tile.length
	destroy_qtip($tile)
	$tile.qtip({
		content: {
			title: item.display_name || langs[lang]["#{item.name}_name"] || item.name,
			text: $($("##{item.name}_tooltip")[0])
		},
		style: {
			classes: "qtip-dark",
			width: 300
		},
		position: {
			my: if $(window).width() > 1024 then "right center" else "bottom left",
			at: if $(window).width() > 1024 then "left center" else "top left",
			viewport: $(window)
		},
		show: { delay: 0 },
		hide: { delay: 100 },
	})

# --- render-on-change HUD cache -----------------------------------------
# The HUD is refreshed from a 50 Hz tick loop; rewriting identical HTML every
# 20 ms burns CPU for nothing, so each value is written only when it changes.
hud_cache = {}

clear_hud_cache = -> hud_cache = {}

set_hud = (key, selector, html) ->
	return if hud_cache[key] == html
	hud_cache[key] = html
	$(selector).html(html)

set_hud_attr = (key, selector, attr, value) ->
	return if hud_cache[key] == value
	hud_cache[key] = value
	$(selector).attr(attr, value)

set_hud_visible = (key, selector, visible) ->
	return if hud_cache[key] == visible
	hud_cache[key] = visible
	if visible then $(selector).show() else $(selector).hide()


update_numbers = ->

	bloon_str = reprnum(Math.floor(basedata.balance()), "long")
	set_hud("bloons", ".bloons", bloon_str)

	set_hud("stats_playtime", "#stats_playtime", reprtime(basedata.play_time))

	set_hud("stats_bloons", "#stats_bloons", bloon_str)
	set_hud("stats_total_bloons", "#stats_total_bloons", reprnum(Math.floor(basedata.total_bloons), "long"))
	set_hud("stats_exp", "#stats_exp", reprnum(Math.floor(bloon.exp)))
	set_hud("stats_exp_to_next_level", "#stats_exp_to_next_level", reprnum(bloon.next_lv_exp + bloon.lv_total_exp - Math.floor(bloon.exp)))

	if shiny_bloon.time_left > 0
		if shiny_bloon.effect == "raindance"
			set_hud("rain_dance_time_left", "#rain_dance_time_left", reprsecs(shiny_bloon.time_left))
		else if shiny_bloon.effect == "clickmult"
			set_hud("click_frenzy_time_left", "#click_frenzy_time_left", reprsecs(shiny_bloon.time_left))
		else if shiny_bloon.effect == "clickexpfrenzy"
			set_hud("click_exp_frenzy_time_left", "#click_exp_frenzy_time_left", reprsecs(shiny_bloon.time_left))

	set_hud_attr("level_progress_value", "#level_progress", "value", bloon.exp - bloon.lv_total_exp)


update_all_numbers = ->
	# updates numbers other than just Bloon count and related stats.
	update_numbers()

	gps_str = reprnum(Math.round(basedata.gps * 10) / 10, "medium")
	set_hud("gps", ".gps", gps_str)
	set_hud("stats_gps", "#stats_gps", gps_str)

	for generator in generators
		set_hud("#{generator.name}_cost", "##{generator.name}_cost", reprnum(Math.floor(generator.cost), "short"))
		if generator in ngens
			if generator.count > 0
				set_hud("#{generator.name}_count", "##{generator.name}_count", "x" + reprnum(generator.count, "short"))
			else
				set_hud("#{generator.name}_count", "##{generator.name}_count", "")
		else
			set_hud("#{generator.name}_count", "##{generator.name}_count", reprnum(generator.count, "short"))
		set_hud("#{generator.name}_gps", "##{generator.name}_gps", reprnum(Math.round(generator.gps * 100) / 100, "medium"))
		set_hud("#{generator.name}_owned", "##{generator.name}_owned", reprnum(generator.count, "short"))
		set_hud("#{generator.name}_tooltip_cost", "##{generator.name}_tooltip_cost", reprnum(Math.floor(generator.cost), "long"))
		set_hud("#{generator.name}_buy1_cost", "##{generator.name}_buy1_cost", reprnum(Math.floor(generator.cost), "short"))
		set_hud("#{generator.name}_buy10_cost", "##{generator.name}_buy10_cost", reprnum(generator.bulk_cost(10), "short"))
		set_hud("#{generator.name}_buy100_cost", "##{generator.name}_buy100_cost", reprnum(generator.bulk_cost(100), "short"))
		set_hud("#{generator.name}_sell1_cost", "##{generator.name}_sell1_cost", reprnum(generator.bulk_sell_value(1), "short"))
		set_hud("#{generator.name}_sell10_cost", "##{generator.name}_sell10_cost", reprnum(generator.bulk_sell_value(10), "short"))
		set_hud("#{generator.name}_sell100_cost", "##{generator.name}_sell100_cost", reprnum(generator.bulk_sell_value(100), "short"))
		set_hud("#{generator.name}_level", "##{generator.name}_level", reprnum(generator.level, "short"))
		set_hud("#{generator.name}_levelup_cost", "##{generator.name}_levelup_cost", reprnum(generator.lvup_cost, "short"))

	# special abbreviation code for cursors and monkeys
	if ("" + gens["cursor"].count).length >= langs[lang].cursor_abbrev_length + 2
		set_hud("cursor_counter", "#cursor_counter", "")
	else if ("" + gens["cursor"].count).length >= langs[lang].cursor_abbrev_length
		set_hud("cursor_counter", "#cursor_counter", langs[lang].cursor_counter_short)
	else
		set_hud("cursor_counter", "#cursor_counter", langs[lang].cursor_counter)

	if ("" + gens["monkey"].count).length >= langs[lang].monkey_abbrev_length + 2
		set_hud("monkey_counter", "#monkey_counter", "")
	else if ("" + gens["monkey"].count).length >= langs[lang].monkey_abbrev_length
		set_hud("monkey_counter", "#monkey_counter", langs[lang].monkey_counter_short)
	else
		set_hud("monkey_counter", "#monkey_counter", langs[lang].monkey_counter)

	for item in itemlist
		if item.locked && item.unlock_condition()
			item.locked = false
		ensure_item_dom(item) unless item.locked

	set_hud_visible("stats_next_level_row", "#stats_next_level_row", bloon.level != bloon.level_cap)
	set_hud("level", ".level", reprnum(bloon.level, "short"))
	set_hud_attr("level_progress_max", "#level_progress", "max", bloon.next_lv_exp)

	set_hud("stats_next_level", "#stats_next_level", reprnum(bloon.level + 1, "short"))

	update_prestige_display()


# --- Prestige tab display ----------------------------------------------

prestige_rank_names = do ->
	names = []
	roman = ["I", "II", "III", "IV", "V"]
	for i in [0...15]
		medal = if i < 5 then "Bronze" else if i < 10 then "Silver" else "Gold"
		names.push("#{medal} #{roman[i % 5]}")
	names

render_prestige_tab = ->
	$tbody = $("#prestige_tiers")
	return unless $tbody.length
	clear_hud_cache()
	$tbody.empty()
	for name, idx in prestige_rank_names
		tier = idx + 1
		$row = $("<tr id='prestige_tier_#{tier}'></tr>")
		$row.append($("<td></td>").text("Tier #{tier}"))
		$row.append($("<td></td>").text(name))
		$row.append($("<td class='prestige-tier-threshold'></td>"))
		$row.append($("<td class='prestige-tier-status'></td>"))
		$tbody.append($row)
	update_prestige_display()

update_prestige_display = ->
	return unless $("#prestige_rank_name").length
	count = basedata.prestige_count
	set_hud("prestige_rank_name", "#prestige_rank_name", if count > 0 then prestige_rank_names[count - 1] else "None")
	set_hud("prestige_mult_value", "#prestige_mult_value", "x" + reprnum(basedata.prestige_mult, "short"))
	if count >= 15
		set_hud("prestige_target", "#prestige_target", "Maximum prestige reached.")
		set_hud_attr("prestige_bar_max", "#prestige_progress_bar", "max", 1)
		set_hud_attr("prestige_bar_value", "#prestige_progress_bar", "value", 1)
	else
		threshold = basedata.prestige_threshold()
		set_hud("prestige_target", "#prestige_target", "Next rank: <b>#{prestige_rank_names[count]}</b> at #{reprnum(threshold, "short")} Bloons earned")
		set_hud_attr("prestige_bar_max", "#prestige_progress_bar", "max", threshold)
		set_hud_attr("prestige_bar_value", "#prestige_progress_bar", "value", Math.min(basedata.total_bloons, threshold))
	set_hud("prestige_earned", "#prestige_earned", reprnum(Math.floor(basedata.total_bloons), "short"))
	for tier in [1..15]
		$row = $("#prestige_tier_#{tier}")
		continue unless $row.length
		set_hud("prestige_tier_#{tier}_threshold", "#prestige_tier_#{tier} .prestige-tier-threshold", reprnum(basedata.prestige_threshold(tier), "short"))
		status = if count >= tier then "Achieved" else if count + 1 == tier then "Next" else "Locked"
		set_hud("prestige_tier_#{tier}_status", "#prestige_tier_#{tier} .prestige-tier-status", status)
	$("#prestige_now").prop("disabled", !basedata.can_prestige())


update_language = ->

	regenerate_tooltips()
	update_all_numbers()


regenerate_tooltips = ->

	for generator in generators
		$("##{generator.name}").off("click.gc2buy")
		if $(window).width() >= 1024
			$("##{generator.name}").on("click.gc2buy", ((name) -> (() -> gens[name].buy(1)))(generator.name))
	# if on a mobile platform, clicking to show tooltips shouldn't autobuy.

	# Destroy existing qtip widgets before rebuilding them, or every call leaks
	# another set of tooltip elements (this runs on resize/language changes).
	destroy_qtip($("##{generator.name}")) for generator in generators
	destroy_qtip($("##{item.name}")) for item in itemlist
	$(".qtip").remove()

	$("#tooltips").empty()
	for generator in generators

		# tooltips are annoying because of this. >_>

		$("#tooltips").append("<div class='generator-tooltip' id='#{generator.name}_tooltip'></div>")
		$("##{generator.name}_tooltip").append("<span id='#{generator.name}_description'>" + (langs[lang]["#{generator.name}_description"] || generator.description) + "</span>" + "
			<hr />
			<span class='lang_tooltip_gps_pre'>Each one produces </span>
			<span class='tooltip-gps' id='#{generator.name}_gps'></span>
			<span class='lang_tooltip_gps_post'> Bloons per second</span>
			<br />
			<span class='lang_tooltip_owned_pre'>You own </span>
			<span class='tooltip-gps' id='#{generator.name}_owned'></span>
			<span class='lang_tooltip_owned_post'></span>
			<br />
			<span class='lang_tooltip_cost_pre'>To buy one costs </span>
			<span class='tooltip-gps' id='#{generator.name}_tooltip_cost'></span>
			<span class='lang_tooltip_cost_post'> Bloons</span>
			<br />
			<button class='tooltip-buy-button' id='#{generator.name}_buy1'><span class='lang_tooltip_buy1'>Buy 1</span> for <span class='tooltip-gps' id='#{generator.name}_buy1_cost'></span></button>
			<button class='tooltip-buy-button' id='#{generator.name}_buy10'><span class='lang_tooltip_buy10'>Buy 10</span> for <span class='tooltip-gps' id='#{generator.name}_buy10_cost'></span></button>
			<button class='tooltip-buy-button' id='#{generator.name}_buy100'><span class='lang_tooltip_buy100'>Buy 100</span> for <span class='tooltip-gps' id='#{generator.name}_buy100_cost'></span></button>
			<button class='tooltip-buy-button' id='#{generator.name}_sell1'><span class='lang_tooltip_sell1'>Sell 1</span> for <span class='tooltip-gps' id='#{generator.name}_sell1_cost'></span></button>
			<button class='tooltip-buy-button' id='#{generator.name}_sell10'><span class='lang_tooltip_sell10'>Sell 10</span> for <span class='tooltip-gps' id='#{generator.name}_sell10_cost'></span></button>
			<button class='tooltip-buy-button' id='#{generator.name}_sell100'><span class='lang_tooltip_sell100'>Sell 100</span> for <span class='tooltip-gps' id='#{generator.name}_sell100_cost'></span></button>
			<hr />
			<span class='lang_tooltip_level_pre'>Level </span>
			<span class='tooltip-gps' id='#{generator.name}_level'></span>
			<span class='lang_tooltip_level_post'></span>
			<button id='#{generator.name}_levelup' class='tooltip-buy-button'>Level up for <span id='#{generator.name}_levelup_cost'></span></button>
		")

		$("##{generator.name}").qtip({
			content: {
				title: langs[lang]["#{generator.name}_name"] || generator.display_name || generator.name,
				text: $($("##{generator.name}_tooltip")[0])
			},
			style: {
				classes: "qtip-dark",
				width: 300
			},
			position: {
				my: if $(window).width() > 1024 then "right center" else "bottom left",
				at: if $(window).width() > 1024 then "left center" else "top left",
				viewport: $(window)
			},
			show: { delay: 0 },
			hide: { fixed: true, delay: 100 },
		})

		$("##{generator.name}_buy1").click(((name) -> (() -> gens[name].buy(1)))(generator.name))
		$("##{generator.name}_buy10").click(((name) -> (() -> gens[name].buy(10)))(generator.name))
		$("##{generator.name}_buy100").click(((name) -> (() -> gens[name].buy(100)))(generator.name))
		$("##{generator.name}_sell1").click(((name) -> (() -> gens[name].sell(1)))(generator.name))
		$("##{generator.name}_sell10").click(((name) -> (() -> gens[name].sell(10)))(generator.name))
		$("##{generator.name}_sell100").click(((name) -> (() -> gens[name].sell(100)))(generator.name))
		$("##{generator.name}_levelup").click(((name) -> (() -> gens[name].levelup()))(generator.name))

	# rebuild the upgrade tooltips that $("#tooltips").empty() just removed
	for item in itemlist when !item.locked
		ensure_item_dom(item)
	clear_hud_cache()

	$(".lang_tooltip_gps_pre").html(langs[lang]["tooltip_gps_pre"])
	$(".lang_tooltip_gps_post").html(langs[lang]["tooltip_gps_post"])
	$(".lang_tooltip_owned_pre").html(langs[lang]["tooltip_owned_pre"])
	$(".lang_tooltip_owned_post").html(langs[lang]["tooltip_owned_post"])
	$(".lang_tooltip_cost_pre").html(langs[lang]["tooltip_cost_pre"])
	$(".lang_tooltip_cost_post").html(langs[lang]["tooltip_cost_post"])

	$(".lang_tooltip_buy1").html(langs[lang]["tooltip_buy1"])
	$(".lang_tooltip_buy10").html(langs[lang]["tooltip_buy10"])
	$(".lang_tooltip_buy100").html(langs[lang]["tooltip_buy100"])
	$(".lang_tooltip_sell1").html(langs[lang]["tooltip_sell1"])
	$(".lang_tooltip_sell10").html(langs[lang]["tooltip_sell10"] || "Sell 10")
	$(".lang_tooltip_sell100").html(langs[lang]["tooltip_sell100"] || "Sell 100")


# debounced: regenerate_tooltips is expensive and used to run on every raw
# resize event, re-creating all qtip widgets continuously while dragging.
resize_timer = null
$(window).resize( ->
	window.clearTimeout(resize_timer) if resize_timer
	resize_timer = window.setTimeout(( ->
		regenerate_tooltips()
		update_all_numbers()
	), 250)
)

# main game loop

# a single tick never applies more than 5 minutes of game time: without this,
# sleeps, suspended tabs or backwards clock jumps pass unbounded (or negative)
# ms into the simulation
MAX_TICK_MS = 5 * 60 * 1000

last_update_time = new Date()

updateF = (ms) ->
	basedata.update(ms)
	battle.update(ms)
	shiny_bloon.update(ms)
	update_numbers(ms)
	animate_plus_markers(ms)

update = ->
	new_update_time = new Date()
	ms = new_update_time.getTime() - last_update_time.getTime()
	last_update_time.setTime(new_update_time.getTime())
	ms = 0 unless isFinite(ms)
	ms = Math.max(0, Math.min(ms, MAX_TICK_MS))
	updateF(ms)
