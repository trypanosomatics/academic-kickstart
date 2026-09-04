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
