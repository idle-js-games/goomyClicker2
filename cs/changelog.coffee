# Update history shown in the Changelog tab.
# Entries are traced back from this repository's git history (oldest at the
# bottom); keep adding new entries at the top.

changelog_entries = [
	{
		date: "2026-10-10"
		version: "v1.3"
		title: "Prestige & cost formula corrections"
		changes: [
			"Prestige thresholds now count Bloons earned in the current run instead of lifetime; the progress display shows the run total."
			"Fixed: prestige left a tower's level-up cost inflated (it was never reset when the tower's level reset)."
			"The customisable cost formula with the 15% compound fallback now applies to building/monkey purchase costs (per-tower balance via set_cost, e.g. Cursor at 10% and Super Monkey at 20% per unit). Level-up costs are back to the classic formula (base cost x100, +35% per level)."
		]
	}
	{
		date: "2026-10-10"
		version: "v1.3"
		title: "Shop UX polish & long-session hardening"
		changes: [
			"Buy and Sell buttons in the hover menu now show their prices on the button itself (e.g. Buy 10 for 5.2K, Sell 10 for 1.2K); the separate cost lines are gone."
			"Fixed: upgrade tiles no longer duplicate per prestige; the shop pane (and its monkey images) is built exactly once and Monkey Ace's tile pointed at a deleted image file; menu tabs scroll horizontally when they overflow; currency uses compensated summation so huge balances no longer drift past the 2^53 precision ceiling; Shiny Bloon effects Click EXP Frenzy (x10 EXP/click for 20s) and Level Up are now actually implemented; prestige clears active shiny buffs; the HUD only rewrites when values actually change."
			"Changed: Eternal Bloon stages are now labelled Eternal Bloon (Tier X); retreating a boss fight resets its HP to full; failed and retreated fights now say \"Build up your BPS and re-engage when ready\"."
		]
	}
	{
		date: "2026-10-10"
		version: "v1.3"
		title: "Prestige, bulk-buy costs & Sell 10/100"
		changes: [
			"New Prestige tab: prestige at lifetime Bloons-earned thresholds (1 billion for the first, x100 per tier, 15 tiers: Bronze I-V, Silver I-V, Gold I-V). Each prestige grants a permanent x2 global earnings and battle damage boost and keeps battle progress."
			"The generator hover menu now shows the total cost of buying 10 or 100 monkeys/towers at once."
			"Sell 10 and Sell 100 are back in the hover menu; the bulk buy/sell loops were hardened (this was the bug that removed them)."
			"Before any bloon is defeated in battle, the main Bloon now shows a Red Bloon instead of the placeholder image."
			"Guarded the legacy prestige level-up loops so astronomic totals can never freeze the game."
		]
	}
	{
		date: "2026-10-10"
		version: "v1.3"
		title: "Upgrade cost rework, battle retreat & stability fixes"
		changes: [
			"Reworked the upgrade (level-up) cost formula: it is now customisable for each building/monkey via Generator#set_levelup_cost, with a 15% compound fallback (base cost x100, +15% per level) wherever no custom balance is set."
			"First per-tower custom balance: Cursor level-ups are cheaper (x50 base cost), Super Monkey level-ups are premium (x200 base cost, +20% per level)."
			"Boss battles: new Retreat button ends a fight early and halts the boss at its remaining HP, so you can build up production and re-engage later. While a fight is active your BpS is channeled into damaging the boss and Bloons production is halted."
			"Settings now has Save Now and Load Saved Progress buttons for manual save control."
			"Stability fixes from the long-session audit: mouse input on touch-capable (hybrid) devices, qtip widget leak on resize, upgrade tooltips rebuilt after tooltip regeneration, unlocked upgrades restored when loading a save, NaN-proof save importing, clamped game ticks with capped (24h) offline gains, and Web Audio node cleanup."
			"New Changelog tab (this page) tracing updates back to the first public release."
			"Completed a long-session degradation audit; see docs/BUG_AUDIT.md."
		]
	}
	{
		date: "2026-05-06"
		version: "v1.2"
		title: "Bloon rebrand & battle fixes"
		changes: [
			"Renamed all remaining Goomy references to Bloon and fixed bloon images (PRs #6-#8)."
			"Boss fight timer is now driven by the main update loop and updates smoothly."
			"Normalised bloon/monkey assets, fixed battle save state and removed stale SVG duplicates (PR #9)."
		]
	}
	{
		date: "2026-05-04"
		version: "v1.2"
		title: "Boss battle system & upgrade logic"
		changes: [
			"New Battle tab: 30-second boss fights against an escalating line of Bloons, from Blue Bloon up to B.A.D and endless Eternal Bloon stages (PRs #4-#5)."
			"Defeating bosses grants permanent Tap and Bloons-per-second reward multipliers."
			"Improved boss scaling and theme naming; polished reset controls and battle formatting."
		]
	}
	{
		date: "2026-05-04"
		version: "v1.2"
		title: "UI rework & runtime fixes"
		changes: [
			"Full UI rework: Shop / Battle / Settings tabs, stats sidebar and responsive layout (PR #1)."
			"Fixed launch crash (missing IIFE closing brace) and other runtime JavaScript errors (PR #2)."
			"Standards-mode doctype, removed legacy analytics script errors, trademark text fixes (PR #3)."
		]
	}
	{
		date: "2022-06-02"
		title: "Number formatting update"
		changes: [
			"Updated number formatting and added new large-number names."
			"English language pack and page updates."
		]
	}
	{
		date: "2022-05-14"
		title: "GitHub Pages hosting"
		changes: [
			"Set up and adjusted GitHub Pages hosting (CNAME)."
		]
	}
	{
		date: "2021-12-28"
		title: "Content refresh"
		changes: [
			"Large content and asset upload."
			"Number formatting and English language pack updates."
		]
	}
	{
		date: "2014-10-01"
		version: "v0.354 (pre-alpha)"
		title: "Initial public release"
		changes: [
			"First public release, originally as Goomy Clicker 2."
			"Cursors and 15 monkey/tower types with tiered upgrades, Shiny Bloon effects, Sliggoo/Goodra prestige and save export/import."
		]
	}
]

render_changelog = ->
	$list = $("#changelog_list")
	return unless $list.length
	$list.empty()
	for entry in changelog_entries
		meta = entry.date + (if entry.version then "  \u00b7  " + entry.version else "")
		$entry = $("<div class='changelog-entry'></div>")
		$entry.append($("<div class='changelog-meta'></div>").text(meta))
		$entry.append($("<h3 class='changelog-title'></h3>").text(entry.title))
		$changes = $("<ul class='changelog-changes'></ul>")
		for change in entry.changes
			$changes.append($("<li></li>").text(change))
		$entry.append($changes)
		$list.append($entry)

@changelog_entries = changelog_entries
@render_changelog = render_changelog
