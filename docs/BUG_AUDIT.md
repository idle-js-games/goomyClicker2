# Long-session ("full time") degradation audit — Bloons Clicker

Bugs and hazards that make the app slower, buggier, or permanently broken the
longer it is played (long sessions, many prestige cycles, many reloads).
Severity: **HIGH** = breaks or degrades state permanently / grows unbounded;
**MED** = degrades over time or misbehaves in common flows; **LOW** = latent or
cosmetic.

> **Status 2026-10-10:** Fixed in v1.3 — #2 (item DOM duplication), #3 (qtip
> leak), #4 (upgrade tooltips), #5 (unlocked upgrades), #6 (NaN poisoning),
> #10/#11 (tick clamp + capped offline gain), #12 (unconditional HUD
> rewrites), #15 (Web Audio), #16 (`unbind()` misuse), #17 (hybrid mouse
> input), #20 (missing shiny effects), #21 (prestige keeping shiny buffs),
> #22 (`buy(0)`/`sell(0)` range) and #23 (2^53 drift — compensated
> summation; the pair (value, compensation) tracks the true sum). Also fixed:
> Monkey Ace's shop tile pointed at a deleted image. Deferred pending further
> analysis: #1 (battle trophies).
>
> **Status 2026-10-15 (v1.3.3):** A second, runtime-exploitable pass was done —
> see "Runtime-exploitable findings" below. All of them are fixed by the
> `clamp_value` hard cap (`cs/basedata.coffee`), the `Generator.MAX_LEVEL` /
> `MAX_BLOON_LEVEL` caps, and the bounded level-up loops.

## Runtime-exploitable findings (v1.3.3)

These were reachable at runtime from a hand-edited save string (the save codec
accepts any digit string, and the in-app Import button is commented out, so
injection is via the browser console / `localStorage`). All are fixed; each was
reproduced in a JSDOM harness before and after the fix.

1. **HIGH — Generator level cap sat above the overflow point.** The import cap
   was `999999`, but `1.3^(L-1)` is `Infinity` past L=2706 and `1.35^(L-1)`
   past L=2342. A level in 2342…999999 imported cleanly and made `gen.gps` /
   `lvup_cost` `Infinity`. With `count = 0` it became `NaN`, which `earn()`
   rejects: all production stopped silently and the broken state was re-saved
   every 10 s. Fixed: `Generator.MAX_LEVEL` / `MAX_COUNT` clamp both the import
   path and the live `levelup()`/`buy()` paths, and every derived value is
   clamped.

2. **HIGH — Unbounded `bloon.gain_exp` loop = main-thread freeze.** Unlike
   `sliggoo`/`goodra.gain_exp`, the Bloon's loop had no guard and ran
   `recalc_gpc()` + `update_all_numbers()` (a full DOM rewrite) per level.
   `bloon_exp` and `goodra_exp` were imported unclamped, and `parseInt` of a
   long digit field returns `Infinity`, so one save froze the tab for ~68 s
   (scale the digits and it is unbounded). Fixed: the loop carries a
   `guard >= 100000` break, exp fields are clamped to `MAX_EXP`, and
   `bloon.level_cap` is clamped to `MAX_BLOON_LEVEL`.

3. **HIGH — Per-tick earn path overflowed before dividing.** `gps * ms / 1000`
   overflows for a *finite* large `gps`; `earn()` then discards the `Infinity`
   gain, so earnings vanished with no error. Fixed: `gps * (ms / 1000)` plus
   `clamp_value` in both `basedata.update` and the offline grant.

4. **MED — Live level-up bypassed the cap and lost data.** `Generator#levelup`
   never checked the cap, so levels earned in play were silently dropped on the
   next load. Fixed by the same cap check.

5. **MED — `add_precise` guarded inputs but not the result.** Finite + finite
   could reach `Infinity`, and `Infinity < Infinity` is false, so every purchase
   became free. Fixed: `clamp_value` on the addend, the sum and the compensation
   term.

6. **MED — Eternal Bloon HP `Infinity` at high stages** inside the allowed
   `MAX_ETERNAL_STAGE` range (unkillable fight). Fixed with `clamp_value`.

7. **LOW — Autosave-conflict notice was ambiguous** ("Reload to sync"). Reworded
   to state that autosaving is off and that Save Now overrides the conflict.

## A. Unbounded DOM / memory growth

1. **HIGH — Battle trophies grow forever.** `battle.win` appends a
   `#battle_trophies` div per defeated boss and nothing ever trims it. The
   Eternal Bloon chain is infinite, so after long play the Battle tab contains
   thousands of nodes; nanoScroller re-layouts and rendering get slower over
   time. (`cs/battle.coffee`)

2. **HIGH — Item DOM duplicated on every reset/prestige.** `basedata.reset()`
   re-locks all items (`locked = true`) but leaves their `#<item>` divs (hidden
   via `.hide()` when bought) in `#items`. When the unlock condition is met
   again, `update_all_numbers` appends *another* div with the same id plus a
   second tooltip div, a second qtip and a second click handler. Every prestige
   cycle leaks one copy of each re-earned upgrade and creates duplicate-id
   selector ambiguity. (`cs/output.coffee`, `cs/basedata.coffee`)

3. **HIGH — qtip widgets leak on every window resize.** `regenerate_tooltips()`
   is called from a `$(window).resize` handler with no debounce. Each call
   re-initialises 16+ qtip widgets without ever calling `qtip("destroy")`;
   `$(".qtip").empty()` only empties the old tooltip elements, which remain in
   the body. Drag-resizing the window (or mobile orientation changes) leaks
   tooltip DOM + jQuery data continuously. (`cs/output.coffee`)

4. **MED — Upgrade tooltips destroyed and never rebuilt.** `regenerate_tooltips`
   does `$("#tooltips").empty()`, deleting the `#<item>_tooltip` content nodes
   referenced by each item's qtip. Item tooltips are only created at unlock
   time, so after any resize, language change or reset the upgrade tooltips are
   empty/blank. (`cs/output.coffee`)

## B. Save / reload state corruption (compounds across sessions)

5. **HIGH — Unlocked-but-unbought upgrades vanish after reload.**
   `_import_save_0_10` restores `locked = false` for previously unlocked items,
   but `update_all_numbers` only creates the item's DOM when
   `item.locked && item.unlock_condition()` — which is then false. The upgrade
   is never rendered again and can never be bought. The longer a save is
   reused, the more upgrades get bricked. (`cs/loadsave.coffee`,
   `cs/output.coffee`)

6. **HIGH — NaN poisoning from unvalidated save fields.** `parseFloat` /
   `parseInt` results in `import_save` are never validated. A single `NaN` in
   `bloons`, a generator `count` or `level` propagates: `Generator#buy`'s
   `basedata.bloons < NaN` is always false → infinite free purchase loop,
   `bloons` becomes `NaN`, and the corrupted state is re-saved every 10 s.
   One corrupt save permanently bricks the game. (`cs/loadsave.coffee`,
   `cs/generator.coffee`)

7. **MED — Autosave throws unguarded.** `save_to_local_storage` runs every 10 s
   in `setInterval` with no try/catch. In private-mode / quota-exceeded /
   disabled-localStorage browsers it throws on every tick forever (console
   spam) and progress is silently never persisted. (`cs/save.coffee`,
   `cs/startup.coffee`)

8. **MED — Two tabs fight over one save.** Autosave is last-writer-wins every
   10 s with no cross-tab guard (storage events/locks), so two open tabs keep
   overwriting each other's progress and can roll the player backwards.

9. **LOW — Save format version drift.** `export_save` stamps `d01_version =
   "0.12"` while the UI reports `0.354 (pre-alpha)` / `v1.2 (release)`, making
   future save migrations ambiguous.

## C. Tick-loop / timing hazards

10. **HIGH — `ms` is not clamped in the main loop.** `update()` computes the
    real elapsed ms and passes it to `basedata.update`, `shiny_bloon.update`,
    etc. After a laptop sleep, a suspended tab, or a backwards NTP clock jump,
    `ms` can be hours long or **negative**. `battle.update` guards `ms > 0`, but
    `basedata.update` does not: negative ms *subtracts* bloons/exp/play-time,
    huge ms grants days of production instantly and instantly burns the shiny
    cooldown. (`cs/output.coffee`, `cs/basedata.coffee`, `cs/shiny.coffee`)

11. **MED — Unbounded offline gain on load.** `load_save_from_local_storage`
    backdates `last_update_time` to the save time, so the first tick after
    loading an old save can be weeks of ms: instant production, instant exp
    levels, inflated `play_time`. No cap and no "offline progress" sanity
    limit. (`cs/loadsave.coffee`)

12. **MED — 50 Hz unconditional DOM rewrites.** `setInterval(update, 20)`
    rewrites ~10 `innerHTML` fields (`#stats_playtime`, `.bloons`, counters…)
    every 20 ms even when nothing changed. Long sessions on low-end hardware
    thermally throttle; the app feels progressively laggier. No render-on-
    change diffing. (`cs/output.coffee`)

13. **LOW — Background-tab throttling loses boss fights.** When the tab is
    backgrounded, `setInterval` throttles to ≥1 s while `battle.timer` keeps
    counting in real time, so a boss fight can time out while the player looks
    at another tab.

14. **LOW — Layout thrash per click.** `PlusMarker` measures the appended
    element's width/height (forced reflow) on every click and rewrites `style`
    per frame per marker. Fast clicking causes jank.

## D. Audio graph

15. **MED — Web Audio nodes never disconnected.** `play_tone` creates an
    oscillator + gain per sound and connects to `ctx.destination` without any
    `onended` disconnect; `start_procedural_music` nodes are `stop()`ped but
    never disconnected. Over a long session the audio node graph accumulates
    (worst in Safari) and audio can crackle/degrade. (`cs/audio.coffee`)

## E. Event handlers / UI lifecycle

16. **MED — `unbind()` misuse in `regenerate_tooltips`.** `$("##{name}").unbind()`
    removes *all* handlers (including qtip's internals) before rebinding only
    the desktop click; combined with #3 this thrashes widget state on every
    resize.

17. **MED — Mouse input dead on touch-capable devices.** `touche.min.js`
    patches `jQuery.fn.on` so every `.click(fn)` binding becomes `touchend`
    *only* whenever `"ontouchstart" in window` (any touchscreen laptop, tablet
    or touch-emulating browser). Mouse clicks fire `click`, not `touchend`, so
    tabs, buying, selling and level-up buttons silently do nothing with a
    mouse. (`lib/touche.min.js`, every `.click` binding in `cs/input.coffee` /
    `cs/output.coffee`)

18. **LOW — Shiny Bloon click handlers accumulate.** `$("#shiny_bloon").click(...)`
    is bound additively on every appearance and only cleared via `unbind()` on
    click; any future reappearance path double-binds.

19. **LOW — Stale nanoScroller.** `nanoScroller()` is initialised once; content
    in `#genbar` grows (items, changelog, trophies) without
    `.nanoScroller()` refresh.

## F. Economy / logic drift over long play

20. **LOW — Documented shiny effects missing.** The comment table in
    `cs/shiny.coffee` promises "Click EXP Frenzy" (0.95%) and "Level Up"
    (0.45%), but every spinner branch ≥ 0.985 falls through to `"bloons"`, so
    the real distribution is 61.5% bloon bonus and the documented balance is
    wrong.

21. **LOW — Prestige ignores active shiny effects.** `basedata.reset()` does
    not reset `raindance_mult`, `frenzy_clickmult` or the shiny effect timers,
    so a ×12/×704 buff survives a full reset.

22. **LOW — Latent `buy(0)`/`sell(0)` range bug.** CoffeeScript `for i in [1..n]`
    with `n = 0` compiles to a *descending* loop and would buy/sell 2 units.
    Current callers always pass ≥ 1.

23. **LOW — Float precision ceiling.** Costs reach 30e15+; above 2^53 the
    `bloons += gps * ms / 1000` accumulator stops being exact, so balances
    drift and `Math.floor` display diverges from stored value.

24. **LOW — Cosmetic `battle.render_values`.** `@hp || bloon.hp` treats an
    exact 0 HP as falsy and displays the max instead.

## G. Misc

25. **LOW — `window.import_save` shadowing.** `zzz_interface.coffee` exports
    `@import_save = load_save_from_local_storage`, shadowing the real
    `import_save` string parser for console users.

26. **LOW — `Generator#show_tooltip` calls `qtip("lol")`** — an invalid qtip
    method; dead code that throws if ever invoked.

27. **LOW — Self-closing `<canvas />`** in `index.html` is invalid HTML (works
    by luck in browsers).

## Recommended fix priority

1. Clamp `ms` (0…5 min) in the game loop and cap offline gain (#10, #11).
2. Validate every loaded save field; reject/repair NaN (#6).
3. Make item DOM lifecycle idempotent: show/hide instead of re-append, rebuild
   tooltips after `$("#tooltips").empty()` (#2, #4, #5, #16).
4. Debounce resize and `qtip("destroy")` before re-init (#3).
5. Cap/summarise `#battle_trophies` (#1).
6. Wrap autosave in try/catch (#7).
7. Disconnect Web Audio nodes on `ended` (#15).
8. Render-on-change for the hot HUD (#12).
