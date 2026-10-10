start_if_loaded = ->
	init_input()
	render_changelog()
	render_prestige_tab()
	change_language(lang)
	load_save_from_local_storage()
	battle.render()
	setInterval(update, 20)
	setInterval(save_to_local_storage, 10000)

startup = ->
	start_if_loaded()

$(document).ready(startup)
