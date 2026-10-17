# AGENTS.md

Client-side single-player idle game. GitHub Pages serves the **repository root
of `master`** (`build_type: legacy`, `source.path: /`) at
https://otheruser325.github.io/BloonsClicker/ ; `docs/CNAME` is only the custom
domain file, `docs/` is not the Pages source. Pushing `master` is the deploy.

## Build

`./compile` concatenates `cs/*.coffee` into the generated bundle `gc2.js`.
CoffeeScript sources under `cs/` are the real code — **never edit `gc2.js` by
hand**; edit `cs/` and re-run `./compile`.

## Save format

- Text save: `||`-separated fields; upgrade state is a bitfield string.
- Codec lives only in `lib/abcdef.js` (`sstr_to_b64`/`b64_to_sstr`/
  `bin_to_sstr`/`b64_to_bin`). Loaded at `index.html`; there is no second copy.
- The binary-field length header counts **bytes** while each decoded unit is a
  4-bit **nibble**; the counter must be doubled on entering binary mode or half
  of every encoded field is misread.
- Generator counts are serialized with `repr_sstr` and parsed with `parse_num`.
  Plain `String(n)`/`parseInt` truncates `1e21` to `1` and loses precision on
  large integers.
- `MAX_GENERATOR_COUNT` (1e21) is the largest value that round-trips exactly;
  import clamps to it.
- `MAX_GENERATOR_LEVEL` (999999) caps generator levels on import **and** on the
  live path (`Generator#levelup`). It must stay high: an earlier cap of 300
  silently snapped lategame towers back to 300 on every load, which broke
  long-run saves. Levels above the cap clamp to the cap, never below it.
- Both bounds live on the class as `Generator.MAX_LEVEL` / `Generator.MAX_COUNT`;
  `cs/loadsave.coffee` mirrors them (`MAX_GENERATOR_LEVEL` etc.) so the import
  path cannot admit a value the live path would reject.
- The caps sit just below the point where the cost/production formulas overflow a
  double (`1.3^(L-1)` is `Infinity` past L=2706, `1.15^n` past n=5078), so the
  economy stays finite at the cap. Do not raise them past those points.

## Multipliers

- `basedata.gps` / `basedata.gpc` are the **earnings** values: they carry
  `basedata.prestige_mult` and are what the HUD and click handler use.
- `basedata.damage_gps` / `basedata.damage_gpc` are the **battle** values:
  identical but with `prestige_mult` divided out. Prestige is an earnings
  multiplier only, so it must never feed boss damage. `cs/battle.coffee` reads
  the `damage_*` pair for passive damage and taps.
- `cs/recalc.coffee` computes all four in one pass: per-building `gen.gps`
  already includes every global multiplier plus prestige, so summing
  `count * gps` yields the total directly and `damage_gps = gps / prestige_mult`.
  `prestige_mult` is a power of two, so that division is exact.
- Any new global multiplier (like `battle.bps_mult`) belongs in `global_mult`,
  which is applied once to every building before the sum. Do not multiply the
  total a second time.

## Number formatting

`lib/reprnum.js` holds the suffix tables. `__apfx`/`__bpfx` are the long-form
illions and **every entry past the empty slot must start with a leading space**
(`" million"`, not `"million"`), or output glues the word onto the digits
(`1.00000million`). The short tables `__aspfx`/`__bspfx` use no spaces. The
illion tables run to quinquagintillion (10^153); past the last entry the
formatter falls back to `K<sup>n</sup>` notation.

## Progression

- Bloon EXP/s is `basedata.expps`. It scales with the Cursor building:
  `(0.2 + 0.1 * (cursor.level - 1)) * cursor.count` — each Cursor level adds
  +0.1 EXP/s per Cursor on top of the 0.2 base.
- Prestige resets generators, Bloons and upgrades but keeps battle progress.
- The Bloon's level is **derived from exp**, not saved; only `bloon.exp` is
  serialized. `bloon.gain_exp` replays the level-ups, so its loop must stay
  bounded (see Hardening).
- `bloon.level_cap` starts at 100 and is raised by Goodra, but it is always
  clamped to `bloon.MAX_BLOON_LEVEL` (999). `MAX_BLOON_LEVEL` exists because
  `bloon.next_lv_exp = level * level * 100` overflows a double around level
  1.34e153; an uncapped level would stop level-ups and freeze the tick loop.

## Releases

Bump the displayed version in **two** places: the `.version` span in
`index.html` and the top entry of `cs/changelog.coffee` (`changelog_entries`,
newest first). `docs/CNAME` is unrelated to the Pages source.

## Hardening

`index.html` carries a strict CSP (`default-src 'self'`, `connect-src 'none'`,
`object-src 'none'`) plus SRI `sha384` hashes on every vendored library. When a
file in `lib/` changes, recompute its hash:
`openssl dgst -sha384 -binary lib/x.js | openssl base64 -A`.

`cs/basedata.coffee` defines `MAX_VALUE` (1e308) and `clamp_value(n)`, the single
guard that keeps every number in the simulation finite. Finite + finite
arithmetic can still overflow a double, and an `Infinity`/`NaN` that reaches an
accumulator is sticky: `Infinity < Infinity` is false (so an infinite balance
would make every purchase free) and the value is re-saved. `clamp_value` pins
values to `±MAX_VALUE` and maps `NaN` to 0. Apply it to any new product, sum or
`Math.pow` result that feeds `basedata`, `gen.gps`, `gen.lvup_cost` or the HUD.

Two things must never be left unbounded:

- **Level-up loops.** `bloon.gain_exp` runs `recalc_gpc()` +
  `update_all_numbers()` (a full DOM rewrite) per level, so it carries a
  `guard >= 100000` break and clamps `level_cap` to `MAX_BLOON_LEVEL`.
  `sliggoo`/`goodra.gain_exp` have the same guard. Any loop driven by an
  imported value needs one.
- **Imported exp.** `MAX_EXP` (1e15) caps the bloon/sliggoo/goodra exp fields.
  `parseInt` of a long all-digit field returns `Infinity`; an unclamped exp was
  enough to freeze the tab for a minute on load.

Offline progress (`cs/loadsave.coffee`) multiplies `gps` by `(offline_ms / 1000)`
in that order on purpose: `gps * offline_ms / 1000` overflows before the divide.
Keep the parenthesised form in `basedata.update` too.

Debug handles (`bloon`, `battle`, `sliggoo`, `goodra`, `recalc`, `clamp_value`)
are exported from `cs/zzz_interface.coffee` for harnesses; the bundle is an IIFE,
so anything not exported there is unreachable from a test.

## Testing

No test infrastructure in-repo. Verification is done in a scratch JSDOM harness
outside the repo that boots `index.html` scripts (`runScripts: "outside-only"`)
and exercises the exported game globals (`export_save`/`import_save`, `gens`,
`bitfield_to_sstr`, `b64_to_bin`, `basedata`). Keep such harnesses out of the
repository.
