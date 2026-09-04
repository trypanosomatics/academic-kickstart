# Local template overrides

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

The Academic v4 site carried these badges through four local template edits.
Hugo Blox needs three files, only one of which is a full copy of an upstream
template.

| File | Kind | Notes |
|---|---|---|
| `_partials/functions/get_doi.html` | new | Reads `hugoblox.ids.doi`, falling back to a top-level `doi`. |
| `_partials/components/research-metrics.html` | new | The badge markup. `style: "donut"` for single pages, `"compact"` for list items. |
| `_partials/hooks/head-end/research-metrics.html` | new | Loads the two vendor scripts and emits `citation_doi`. Uses Hugo Blox's `head-end` hook, so it overrides nothing. |
| `_partials/page_footer.html` | **override** | 11-line upstream file, verbatim plus one `if`. Chosen over overriding `single.html`, which is 352 lines and would have to be re-merged on every module upgrade. |
| `_partials/views/citation.html` | **override** | 51-line upstream file, verbatim plus one partial call in each of the two citation-style branches. |

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
- **CSP.** If `hugoblox.security.csp.policy` is ever set, both hosts need
  allowing in `script-src` and `connect-src`.
- **Placement differs from the old site.** v4 put the badges in the publication
  metadata table. They now sit at the end of the article, above the tags and
  author cards, because that is reachable through the 11-line `page_footer.html`
  rather than a 352-line `single.html` copy. Matching the old placement exactly
  is possible but costs that larger override.
- **Not on author or tag pages.** Those list publications with the `card` view,
  which has no badge. Adding one means also overriding
  `_partials/views/card.html` (228 lines) — deliberately not done.

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
