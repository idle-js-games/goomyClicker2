items = {}
itemlist = []
item_ids = {}

class Item

	constructor: (name, id) ->

		@name = name

		@display_name = ""
		@description = ""
		@caption = ""

		@id = id

		@cost = 0
		@bought = false

		@locked = true
		@unlock_condition = ->

		@buy = ->
			if @locked or basedata.balance() < @cost
				return false
			basedata.spend(@cost)
			@bought = true
			play_sound("upgrade")
			recalc() # everything you buy has recalculatory effects.

		items[name] = this
		item_ids[id] = this
		itemlist.push(this)
