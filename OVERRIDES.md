# Local template overrides

> Several of these work around **upstream bugs that are still present in
> `HugoBlox/kit@main`**. If they are fixed upstream the override can be dropped —
> see `PULL-REQUESTS.md` for the analysis and proposed patches.

Every file in `layouts/` overrides one from the `blox` module. Record what was
copied, from which version, and exactly what changed — without this the next
module upgrade is archaeology.

Upstream module: `github.com/HugoBlox/kit/modules/blox`
Version at time of copy: `v0.0.0-20260527025321-61f41d3667f1`

| File | Upstream source | Local change |
|---|---|---|
| `_partials/functions/process_responsive_image.html` | same path | Guarantee a non-nil `fallback`. Upstream only emits breakpoints where the source is at least as wide as the requested size, so an image narrower than all of them returns `fallback` as `""` and every caller doing `.fallback.RelPermalink` errors the build. Triggered here by `assets/media/authors/aleacker.jpg` (72×89 against sizes 160/240/320/480). Upstream bug; the patch is at the end of the file, clearly marked. |

## When upgrading the blox module

For each row: diff the new upstream file against the version noted above, and
re-apply the local change on top of the new file rather than keeping the old
copy. Then update the version recorded here.

---

## Research metrics (Altmetric + Dimensions)

The Academic v4 site carried these badges through four local template edits
(`li_card.html`, `li_compact.html`, `publication/single.html` and a patched
`page_author.html`). Hugo Blox needs five files, two of which are full copies of
upstream templates.

| File | Kind | Notes |
|---|---|---|
| `_partials/functions/get_doi.html` | new | Reads `hugoblox.ids.doi`, falling back to a top-level `doi`. |
| `_partials/functions/metrics_scope.html` | new | **Single source of truth for *where* badges render** — the landing page and the publications section. Asked by the component, by `views/card.html`, and by the head-end hook, so markup and scripts cannot drift apart. |
| `_partials/components/research-metrics.html` | new | The badge markup. `style: "donut"` for single pages, `"compact"` for list items. |
| `_partials/hooks/head-end/research-metrics.html` | new | Loads the two vendor scripts and emits `citation_doi`. Uses Hugo Blox's `head-end` hook, so it overrides nothing. |
| `_partials/page_footer.html` | **override** | 11-line upstream file, verbatim plus one `if`. Chosen over overriding `single.html`, which is 352 lines and would have to be re-merged on every module upgrade. |
| `_partials/views/citation.html` | **override** | 51-line upstream file, verbatim plus one partial call in each of the two citation-style branches. |
| `_partials/views/card.html` | **override** | 229-line upstream file, verbatim plus three LOCAL blocks: a scope test, that test folded into `$hasMeta`, and the badges on the bottom row beside "Read more". Carries the Featured Publications block, which reaches this view through the one-line `views/article-grid.html`. |

### Alignment

Altmetric and Dimensions are separate vendors that inject their own markup at
runtime, each with its own intrinsic height and baseline, so side by side they
sit at different heights. Utility classes cannot fix that: the elements being
aligned do not exist until the vendor scripts run, so nothing Hugo emits can
carry a class on them.

The head-end hook therefore ships a small `.hb-metrics` stylesheet that flexes
the row, kills baseline gaps (`line-height: 0`, `vertical-align: middle`) and
forces one common height on whatever element type each vendor uses —
`img`, `svg` or `iframe`. Compact list badges are 20px; the `--donut` variant on
single pages is 64px.

If a vendor changes its markup to some other element, add it to that rule rather
than reintroducing per-item utility classes.

### Which views carry badges — the completeness audit (2026-09-08)

`blox` ships five item views. Only two can ever show a publication on this site,
and both now carry badges:

| View | Used here by | Shows publications? | Badges |
|---|---|---|---|
| `citation` | `/publications/` list (`view = "citation"` in its `_index.md`) and the landing "Recent Publications" block; also the default for the `cite` shortcode | yes | ✅ override |
| `card` | landing Recent Posts / Recent Talks, `/blog/` and `/events/` lists, author profile pages (`authors/term.html` hardcodes it), tag / category / publication_type term pages — and Featured Publications, via `article-grid` | yes (featured, and every taxonomy listing) | ✅ override, scoped |
| `article-grid` | Featured Publications block | yes | ✅ one-line delegate to `card` |
| `date-title-summary` | nothing | no | ❌ none needed |
| `slides-gallery` | nothing | no | ❌ none needed |

Single publication pages are not a view — they get the donut through
`page_footer.html`.

The two unused views would need one `partial "components/research-metrics"` call
each if a section ever adopted them; the scope rule comes along for free.

Views are dispatched from exactly four places, which is the list to re-check on
a module upgrade: `blox/content-collection/block.html` (default `card`),
`layouts/list.html` (`.Params.view`, default `card`), `layouts/authors/term.html`
(hardcoded `card`), `layouts/_shortcodes/cite.html` (default `citation`).

### Parity with the deployed v4 site

Counts are Altmetric placeholders per page, live site vs. this branch:

| Page | v4 (live) | This branch |
|---|---|---|
| Landing page | 7 | 7 |
| `/publication[s]/` list | 0 | 10 |
| Publication single | 1 | 1 |
| `/publication_types/…` | 0 | 0 |
| `/authors/…`, `/tags/…`, `/categories/…` | 0 | 0 |
| `/post[blog]/`, `/talk[events]/`, `/project[s]/` | 0 | 0 |

The landing page matches exactly, by a different route: v4 got its 7 from the
`card` view (2 featured) plus the **`compact`** view (5, `li_compact.html`); here
it is `card` (2) plus `citation` (5), because the Recent Publications block moved
from `view = 2` to `view: citation` in the migration.

**The publications list is the one deliberate difference** — v4 rendered it with
the theme's unpatched citation view and showed no badges there. Ours does. That
is an improvement, not a regression, but it is a change: say so if anyone asks
why the list looks busier than the old site.

> **Measuring this against the live site: follow the redirect.**
> `https://trypanosomatics.org/…` 301s to `www.`, and `curl` without `-L`
> returns a 47-byte stub in which every `grep -c` is 0. A first pass at this
> table was built from those stubs and was entirely wrong — it read "0 badges
> anywhere on v4", including the home page that plainly has them. Use
> `curl -sL https://www.trypanosomatics.org/…`.

### DOIs are normalised to the bare form

`functions/get_doi.html` strips `https://doi.org/`, `http://dx.doi.org/`, `doi:`
and friends. Both badge services need a bare `10.xxxx/yyyy` in `data-doi` and
render nothing when handed a resolver URL. One publication
(`2023-UranLandaburu-MiniReview-BSTpy`) had the URL form in its front matter;
that is fixed at source too, but the helper no longer depends on it.

### Trade-offs to know

- **These are third-party scripts and cannot be vendored.** Both badges are live
  services whose JS must load from the vendors' own hosts:
  `d1bxh8uas1mnw7.cloudfront.net` (Altmetric) and `badge.dimensions.ai`
  (Dimensions). Hugo Blox otherwise ships everything locally, so this is the one
  place the site calls out to third parties. The head-end hook loads them only
  where a badge can actually appear — publication pages, the landing page, and
  the publications section — so blog, events, projects and author pages stay
  clean. Set `hugoblox.research_metrics.enable: false` in `params.yaml` to drop
  them entirely.

### How the vendor scripts actually behave — measured 2026-09-08

Three things were tested directly, with minimal pages driven through headless
Chrome, rather than taken from the vendors' docs:

1. **One script tag per page is enough, and it must be on that page.** A page
   with the script in `<head>` and two badge spans in the body renders both.
   The *same markup with no script tag renders nothing at all* — no error, no
   box, just absence. This is why `functions/metrics_scope.html` exists: badge
   markup is only ever worth emitting where the hook also loads the scripts.
   Loading them on some *other* page of the site does nothing for this one.
2. **The `once per page` part is the vendors' own advice, and v4 ignored it.**
   The deployed v4 home page fetches `badge.dimensions.ai/badge.js` **seven
   times** — `li_card.html` and `li_compact.html` each emit a `<script>` next to
   every badge. Loading it once in `<head>` is both the documented pattern and
   what this branch does.
3. **`badge.dimensions.ai/badge.js` and `…/static/ai/badge.js` are the same
   file** — byte-identical, same md5, 533 KB. Either URL is fine; no reason to
   change. Altmetric's `embed.js` is a 687-byte loader that injects the real
   bundle from `embed.altmetric.com`.

**The caveat that follows from (1):** badges must be in the HTML the browser
receives. Markup injected 400 ms after `DOMContentLoaded` rendered **nothing**
for either vendor in this harness, even though the Dimensions bundle contains
`MutationObserver` code. Everything here is server-rendered by Hugo, so it does
not bite today — but a future client-side filter or lazy-render over
publications would need `__dimensions_embed.addBadges()` called after the DOM
changes.
- **CSP.** If `hugoblox.security.csp.policy` is ever set, both hosts need
  allowing in `script-src` and `connect-src`.
- **Placement differs from the old site.** v4 put the badges in the publication
  metadata table. They now sit at the end of the article, above the tags and
  author cards, because that is reachable through the 11-line `page_footer.html`
  rather than a 352-line `single.html` copy. Matching the old placement exactly
  is possible but costs that larger override.
- **Not on author, tag, category or publication_type pages.** They list
  publications through the same `card` view as the Featured Publications block,
  so no rule based on the *view* can separate them — the rule is based on the
  *page being rendered*, and lives in `functions/metrics_scope.html`. Without
  it, ~200 taxonomy pages carry badge markup that no script ever animates.
  The v4 site shows no badges there either (see the parity table below).
  Extend `metrics_scope` if the lab later wants them on, say, the
  `/publication_types/` listings — one file, and the scripts follow
  automatically.

---

## Author cards — short bio

`_partials/page_author_card.html` is an **override** (78-line upstream file,
verbatim except the bio block).

Upstream renders `$profile.bio`. In this site's data `bio` is the author's
**full biography** — several paragraphs and headings — because that is what
`layouts/authors/term.html` renders on their profile page, and Hugo Blox has
only the one field. On a card at the foot of an article that is far too much.

The override reads `short_bio` from `data/authors/<slug>.yaml` instead, which
carries the one-liner the Academic v4 site used. `get_author_profile` returns a
fixed dict that does not include `short_bio`, so the override reads the raw
author data via `functions/get_authors_data`.

**There is deliberately no fallback to `bio`.** An author with no `short_bio`
shows name and role only — what the old site did, since its card used the short
`bio` front-matter field, which was empty for some people. Currently `aleacker`
and `mercedes`; add `short_bio:` to their data file to give them a line.

---

## Typography — Google Fonts URL

`_partials/functions/typography.html` is an **override** of the upstream file
(v0.0.0-20260527025321), verbatim except for one delimiter.

Upstream joins discrete font weights with a comma:

```gotemplate
{{ $weight_spec = delimit $role_weights "," }}   {{/* Play:wght@400,700 */}}
```

The Google Fonts CSS2 API separates weights with `;`. A comma is rejected with
**HTTP 400**, and because all families share a single request, one bad entry
drops **every** font on the page — the site silently falls back to system sans
with nothing in the console but a failed stylesheet. The local patch changes the
delimiter to `;`.

This only bites families declared non-variable with more than one weight, which
is why the stock packs never hit it: they set `variable: true` and take the
`100..900` branch.

### A related trap, handled in the font pack rather than here

Upstream hardcodes `100..900` for anything marked `variable: true`. Real axes
are often narrower — Open Sans is `300..800` — and Google rejects the
out-of-range request and drops that family. `data/fonts/tryps.yaml` therefore
declares Open Sans **static** with explicit weights. If a future font pack marks
a role variable, check the family's real axis range first.

**Regression test** — after any change to fonts or to this file:

```bash
hugo --gc
URL=$(grep -oE 'https://fonts.googleapis.com/css2[^"]+' public/index.html | head -1 | sed 's/&amp;/\&/g')
curl -s -o /dev/null -w '%{http_code}\n' "$URL"                  # must be 200
curl -s "$URL" | grep -oE "font-family: *'[^']*'" | sort -u      # must list every family
```
