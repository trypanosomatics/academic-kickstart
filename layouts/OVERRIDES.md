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
