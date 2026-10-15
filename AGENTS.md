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

## Hardening

`index.html` carries a strict CSP (`default-src 'self'`, `connect-src 'none'`,
`object-src 'none'`) plus SRI `sha384` hashes on every vendored library. When a
file in `lib/` changes, recompute its hash:
`openssl dgst -sha384 -binary lib/x.js | openssl base64 -A`.

## Testing

No test infrastructure in-repo. Verification is done in a scratch JSDOM harness
outside the repo that boots `index.html` scripts (`runScripts: "outside-only"`)
and exercises the exported game globals (`export_save`/`import_save`, `gens`,
`bitfield_to_sstr`, `b64_to_bin`, `basedata`). Keep such harnesses out of the
repository.
