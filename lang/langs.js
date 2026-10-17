langs = {};

lang = "en-US";

lang_elements = [

	"title",

	"bloon_counter_pre",
	"bloon_counter_post",
	"gps_counter_pre",
	"gps_counter_post",
	"gpc_counter_pre",
	"gpc_counter_post",
	"level_counter",

	"stats_header",
	"stats_play_time",
	"stats_bloons",
	"stats_total_bloons",
	"stats_gps",
	"stats_gpc",
	"stats_total_total_bloons",
	"stats_exp",
	"stats_exp_to_next_level_pre",
	"stats_exp_to_next_level_post",

	"cursor_counter",
	"cursor_counter_short",

	"monkey_counter",
	"monkey_counter_short",

	"tooltip_gps_pre",
	"tooltip_gps_post",

];

change_language = function(new_lang){

	lang = new_lang;

	update_language();

	for(var a = 0; a < lang_elements.length; ++a){
		var copy = langs[lang][lang_elements[a]];
		if(copy === undefined && langs["en-US"]){
			copy = langs["en-US"][lang_elements[a]];
		}
		$(".lang_" + lang_elements[a]).html(copy);
	}

}
