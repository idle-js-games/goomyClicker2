plus_marker_id = 0

plus_marker_anims = 1000
plus_marker_distance = 100
plus_marker_origradius = 20


class PlusMarker

	constructor: (caption, x, y, anims) ->
		@id = plus_marker_id
		plus_marker_id += 1
		plus_markers[@id] = this
		@caption = caption
		@init_anims = if anims then anims else plus_marker_anims
		@anims = @init_anims
		$("#gamearea").append("<div class='plus_marker' id='plus_marker_#{@id}'>#{@caption}</div>")
		$marker = $("#plus_marker_#{@id}")
		width = $marker.width()
		height = $marker.height()
		@orig_x = Math.max(0, Math.min($(window).width() - width, x - width / 2))
		@orig_y = Math.max(0, Math.min($(window).height() - height, y - height / 2))
		@x = @orig_x
		@y = @orig_y
		@opacity = 1
		$marker.css({left: @x, top: @y, opacity: @opacity})

	update: (ms) ->
		@anims -= ms
		if @anims <= 0
			$("#plus_marker_#{@id}").remove()
			delete plus_markers[@id]
			return
		move_fraction = @anims / @init_anims
		@y = Math.max(0, @orig_y - plus_marker_distance + plus_marker_distance * move_fraction * move_fraction)
		@opacity = move_fraction
		$("#plus_marker_#{@id}").css({left: @x, top: @y, opacity: @opacity})


plus_markers = {}
@plus_markers = plus_markers

animate_plus_markers = (ms) ->
	for own id, plus_marker of plus_markers
		plus_marker.update(ms)
