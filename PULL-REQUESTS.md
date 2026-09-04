# Upstream bug reports / pull requests

Bugs found in [HugoBlox/kit](https://github.com/HugoBlox/kit) while migrating
this site, assessed for whether they are worth contributing back.

**Verdict: yes — four are clean, general bug fixes, plus one smaller
inconsistency.** All were re-checked against `main` @ `68cbf3353012`
(2026-05-27) and are **still present there**; none is specific to our pinned
module version (`blox v0.0.0-20260527025321-61f41d3667f1`).

Every one is reproduced and fixed in this repo already, so each PR is a patch
that has been running in production rather than a theory. Our local versions are
in `layouts/` and recorded in `OVERRIDES.md`.

Path prefix for everything below: `modules/blox/layouts/_partials/`.

---

## PR 1 — Google Fonts weights must be `;`-separated, not `,`

**File** `functions/typography.html:145` · **Severity** high — silently breaks all
web fonts on the page

```gotemplate
{{ $weight_spec = delimit $role_weights "," }}   {{/* Play:wght@400,700 */}}
```

The Google Fonts CSS2 API separates discrete weights with `;`. A comma is
rejected:

```
family=Play:wght@400,700  → HTTP 400
family=Play:wght@400;700  → HTTP 200
```

Because every family is requested in **one** stylesheet URL, a single bad entry
drops *all* fonts on the site. The failure is silent — no console error beyond
one failed stylesheet, and the page just renders in the fallback system font.

**Fix** — one character:

```gotemplate
{{ $weight_spec = delimit $role_weights ";" }}
```

**Who it affects** any font pack with a role declared `variable: false` and more
than one weight. The shipped packs all set `variable: true` and take the
`100..900` branch, which is why it has gone unnoticed.

**Repro** a pack with `families.heading: Play`, `weights.heading: [400, 700]`,
`variable.heading: false`; the emitted `<link>` returns 400.

---

## PR 2 — `100..900` is not a valid range for every variable font

**File** `functions/typography.html:142` · **Severity** medium — silently drops a
family

```gotemplate
{{ $weight_spec = "100..900" }}
```

Hardcoded for anything marked `variable: true`. Real axes are often narrower and
Google rejects an out-of-range request, dropping that family from the response
while still returning 200 for the rest:

```
family=Open+Sans:wght@100..900  → 400
family=Open+Sans:wght@300..800  → 200
```

**Fix** — needs a maintainer decision, so this is worth opening as an *issue
first*. Options, cheapest last:

1. Derive the range from the pack's declared `weights` —
   `printf "%d..%d" (min) (max)` — so the data already in the pack governs.
2. Let a pack declare an explicit range, e.g. `variable: {body: "300..800"}`,
   treating a bare `true` as today's `100..900`.
3. Ship per-family axis metadata (most correct, highest maintenance).

Option 1 is the smallest change and fixes the common case.

**Workaround used here** declare the family static with explicit weights.

---

## PR 3 — Anchor menu links are broken on every page except the home page

**File** `components/headers/navbar.html:85-89` and `108-112` (both branches) ·
**Severity** high — site-wide navigation failure

```gotemplate
{{- if findRE `^#` .URL -}}
  {{- if not $.IsHome -}}
    {{- $url = site.Home.RelPermalink -}}   {{/* computes the prefix … */}}
  {{- end }}
  {{- $url = .URL -}}                        {{/* … then discards it, always */}}
```

The second assignment sits outside the conditional and overwrites the prefix on
every page. The intent is unmistakable, so this is a plain slip rather than a
design choice. Result: from `/publications/foo/`, a `#talks` menu entry links to
`/publications/foo/#talks` instead of the landing page.

**Fix**

```gotemplate
{{- if findRE `^#` .URL -}}
  {{- if not $.IsHome -}}
    {{- $url = printf "%s%s" site.Home.RelPermalink .URL -}}
  {{- else -}}
    {{- $url = .URL -}}
  {{- end -}}
{{- else -}}
```

Apply to **both** occurrences — the dropdown-child branch has the same shape.

**Who it affects** every site whose menu uses landing-page anchors, i.e. the
standard one-page academic layout the templates ship with. Affects the mobile
menu too, which shares the loop.

**Workaround used here** write menu URLs as `/#id` in `menus.yaml`, which
sidesteps the `^#` branch entirely. Worth mentioning in the PR: it means the bug
can be dodged without a template change, so the fix is low-risk to land.

---

## PR 4 — `process_responsive_image` returns an empty fallback for small images

**File** `functions/process_responsive_image.html:76-139` · **Severity** medium —
hard build failure

Breakpoints are only emitted where the source is at least as wide as the
requested size:

```gotemplate
{{ range $width := $sizes }}
  {{ if ge $image.Width $width }}
    …
    {{- if not $fallback_image -}}{{- $fallback_image = $processed -}}{{- end -}}
```

If the source is narrower than **every** requested size, the loop body never
runs, `$fallback_image` stays `""`, and the function returns an empty string as
`fallback`. Every caller then does `$responsive.fallback.RelPermalink` and the
build dies:

```
execute of template failed: can't evaluate field RelPermalink in type interface {}
```

Triggered here by a 72×89 author avatar against `sizes (slice 160 240 320 480)`
in `layouts/authors/term.html`. Any image smaller than the smallest requested
breakpoint does it.

**Fix** — guard before the return, mirroring the non-processable branch which
already does exactly this at line 134:

```gotemplate
{{- if not $fallback_image -}}
  {{- $fallback_image = $image -}}
  {{- if not $srcset_parts -}}
    {{- $srcset_parts = slice (printf "%s %dw" $image.RelPermalink $image.Width) -}}
  {{- end -}}
{{- end -}}
```

**Note for the PR** a build failure on a small avatar is a poor experience; an
alternative is to upscale to the smallest breakpoint. Falling back to the
original is the conservative choice and matches the existing SVG/GIF path.

---

## PR 5 — Reading time ignores `reading_time: false` in card listings

**File** `views/card.html:196-200` · **Severity** low — inconsistency

`single.html:134` gates on `{{ if ne .Params.reading_time false }}`, but
`card.html` renders unconditionally, so a page that opts out still shows a
reading time wherever it appears in a card listing.

`card.html` also recomputes it by word-splitting `.Content` rather than using
Hugo's `.ReadingTime`, which `single.html` uses — slower and can disagree.

**Fix** wrap in the same guard and use `$item.ReadingTime`.

---

## Not worth a PR

| Finding | Why not |
|---|---|
| `site.IsMultiLingual` in `page_edit.html` (blox-bootstrap) | Lives in `HugoBlox/wowchemy-bootstrap-legacy`, which is **archived** — PRs cannot be opened. See `ANALYSIS.md` §4.3. |
| `--hb-font-size-base` declared but consumed by no rule | Dead variable, so `typography.sizes.base` silently does nothing. Whether it *should* drive body size is a design question — **file as an issue**, not a PR. |
| Theme picker inlines all 12 packs (~95 KB/page) | Deliberate, and off by default in some templates. Worth an issue proposing it emit only the configured pack unless the picker is enabled. |
| No `tag-cloud` block | A feature, not a bug. Ours (`hugo-blox/blox/all-access/tag-cloud/`) could be offered as a contribution — see `ANALYSIS.md` §6. |

---

## Before opening anything

- **There is a CLA.** `CONTRIBUTING.md`: *"By submitting a Pull Request, you
  agree to our [CLA](.github/CLA.md). In short: you keep ownership of your code;
  we get a permanent license to use it as part of HugoBlox."* If contributing
  under an institutional affiliation, check that this is acceptable first.
- Repo is MIT, issues are open, forking allowed, and `CONTRIBUTING.md` actively
  solicits bug fixes.
- Re-verify against `main` before submitting — these were checked at
  `68cbf3353012` (2026-05-27) and the repo is active.

**Suggested order.** PR 3 and PR 1 first: both are unambiguous slips with
one-or-two-line fixes and clear reproductions, so they are the easiest to review
and the most valuable to other users. PR 4 next. PR 2 as an issue proposing
option 1 before writing code. PR 5 whenever convenient.

Each should carry a minimal reproduction: a font pack and the failing URL for
PR 1 and 2, a menu config and two rendered pages for PR 3, an image smaller than
160px for PR 4.
