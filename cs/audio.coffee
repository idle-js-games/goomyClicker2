audio =
	context: null
	music: null
	music_nodes: null
	music_started: false
	ensure_context: ->
		return null unless window.AudioContext || window.webkitAudioContext
		@context ?= new (window.AudioContext || window.webkitAudioContext)()
		@context.resume() if @context.state == "suspended"
		@context
	play_tone: (frequency, duration = 0.05, type = "sine", volume = 0.04) ->
		return unless settings.audio
		ctx = @ensure_context()
		return unless ctx
		osc = ctx.createOscillator()
		gain = ctx.createGain()
		osc.type = type
		osc.frequency.setValueAtTime(frequency, ctx.currentTime)
		gain.gain.setValueAtTime(volume, ctx.currentTime)
		gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + duration)
		osc.connect(gain)
		gain.connect(ctx.destination)
		# disconnect on end: otherwise stopped nodes stay attached to the
		# destination and the audio graph grows over a long session
		osc.onended = ->
			try
				osc.disconnect()
				gain.disconnect()
			catch e
				null
		osc.start(ctx.currentTime)
		osc.stop(ctx.currentTime + duration)
	play: (name) ->
		switch name
			when "tap" then @play_tone(520, 0.035, "triangle", 0.035)
			when "buy" then @play_tone(680, 0.06, "square", 0.03)
			when "upgrade" then @play_tone(880, 0.09, "sawtooth", 0.025)
			when "win" then @play_tone(1040, 0.12, "triangle", 0.04)
	init_music: ->
		return unless settings.music
		@music ?= new Audio(audio_asset("main.mp3"))
		@music.loop = true
		@music.volume = 0.18
	start_procedural_music: ->
		ctx = @ensure_context()
		return unless ctx
		return if @music_nodes
		master = ctx.createGain()
		master.gain.setValueAtTime(0.025, ctx.currentTime)
		master.connect(ctx.destination)
		lead = ctx.createOscillator()
		bass = ctx.createOscillator()
		lfo = ctx.createOscillator()
		lfo_gain = ctx.createGain()
		lead.type = "triangle"
		bass.type = "sine"
		lfo.type = "sine"
		lead.frequency.setValueAtTime(261.63, ctx.currentTime)
		bass.frequency.setValueAtTime(130.81, ctx.currentTime)
		lfo.frequency.setValueAtTime(0.5, ctx.currentTime)
		lfo_gain.gain.setValueAtTime(35, ctx.currentTime)
		lfo.connect(lfo_gain)
		lfo_gain.connect(lead.frequency)
		lead.connect(master)
		bass.connect(master)
		lead.start()
		bass.start()
		lfo.start()
		@music_nodes = [lead, bass, lfo, master]
	start_music: ->
		return unless settings.music
		@init_music()
		if @music
			play_promise = @music.play()
			if play_promise && play_promise.catch
				play_promise.catch(=> @start_procedural_music())
		else
			@start_procedural_music()
		@music_started = true
	stop_music: ->
		if @music
			@music.pause()
		if @music_nodes
			for node in @music_nodes
				try
					node.stop() if node.stop
					node.disconnect()
				catch e
					null
			@music_nodes = null
		@music_started = false
	refresh_music: ->
		if settings.music then @start_music() else @stop_music()
	unlock: ->
		@ensure_context() if settings.audio
		@start_music() if settings.music

play_sound = (name) -> audio.play(name)

@audio = audio
@play_sound = play_sound
