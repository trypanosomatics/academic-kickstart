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
| `_partials/hbx/blocks/team-showcase/block.html` | `blox/team-showcase/block.html` | Not a bug — a deliberate content-vs-code trade-off. See "Avatar cropping" below. Also carries the role/affiliation font fix below. |
| `authors/term.html` | same path | Role/affiliation font fix — see "Play on role/affiliations, not just headings" below. Otherwise verbatim. |
| `_partials/hbx/blocks/resume-biography/block.html` | `blox/resume-biography/block.html` | Same font fix, on the name and affiliations. Otherwise verbatim. |
| `_partials/hbx/blocks/content-collection/block.html` | `blox/content-collection/block.html` | Section title was a `<div>`, now a real `<h2>`. See "Section titles" below. Otherwise verbatim. |

## When upgrading the blox module

For each row: diff the new upstream file against the version noted above, and
re-apply the local change on top of the new file rather than keeping the old
copy. Then update the version recorded here.

---

## Wording tweaks: override the i18n string, not the template

A block's copy (button labels, headings like "Find me on") usually comes from
`i18n "some_key" | default "English fallback"`, not a literal in the template.
`config/_default/module.yaml` mounts `source: i18n, target: i18n`, so a same-`id`
entry in the site's own `i18n/en.yaml` overrides just that key — merged
key-by-key on top of the module's `i18n/en.yaml`, everything else untouched. No
`layouts/` copy, no row in the table above.

Check the block's `.html` in the module cache for the `i18n "..."` key before
reaching for a full template override — copying a block just to change a
string means re-diffing that whole file on every future module upgrade for no
reason.

Current site overrides, in `i18n/en.yaml`:

| Key | Module default | This site |
|---|---|---|
| `block_contact_follow_me` | "Find me on" | "Find us on" — `contact-info` doesn't branch this string on `identity.type: organization`, so it says "me" regardless of site type. |

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

### Badge appearance is per context, and configurable

`components/research-metrics.html` takes a **preset name** — `single`,
`citation` or `card` — not a hardcoded style. Each preset says how both vendors
draw their badge there, and `hugoblox.research_metrics.styles.<preset>` in
`params.yaml` overrides any key of it, so re-styling a context is a config edit.

| Context | Preset | Dimensions | Altmetric | Height |
|---|---|---|---|---|
| A publication's own page | `single` | `medium_circle` | `medium-donut` | 64px (`lg`) |
| Citation rows — `/publications/` and the landing list block | `citation` | `small_rectangle` | `4` (bar) | 20px (`sm`) |
| Featured Publications cards | `card` | `small_circle` | `donut` | 40px (`md`) |

Accepted values, from the vendors' own docs (checked 2026-09-08):

- **Dimensions** `data-style`: `small_circle`, `medium_circle`, `large_circle`,
  `small_rectangle`, `large_rectangle`. `data-legend`: `never`, `always`,
  `hover-top`, `hover-right`, `hover-bottom`, `hover-left`.
- **Altmetric** `data-badge-type`: `donut`, `medium-donut`, `large-donut`,
  `bar`, `medium-bar`, `large-bar`, `1`, `4`. `data-badge-popover`: `left`,
  `right`, `top`, `bottom`.

`size` is ours, not a vendor value: the common height both badges are forced to
so two vendors with different intrinsic heights share a baseline. Adding a
fourth size means adding a `.hb-metrics--<name>` rule to the head-end hook.

> **Dimensions `medium_circle` paints an opaque white disc.** At 64px on the
> dark theme that is a bright spot next to Altmetric's transparent donut — it is
> the vendor's own artwork, not something CSS here can recolour. `small_circle`
> (used on the cards) draws a ring instead and sits far more quietly. Worth
> knowing before picking sizes for a dark background.

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

## Avatar cropping on the People grid (`team-showcase`)

The stock block puts every avatar in a forced-square box with `object-contain`
— it fits the whole image inside the square rather than cropping to fill it.
The module's own README says why: it expects **pre-cropped square images**
("Use square WebP avatars... ~400×400px... Names center-cropped").

This site's avatars were never held to that rule — 20 lab members over a
decade, uploaded whatever aspect ratio their photo happened to be. `object-contain`
made that visible: a square source fills the box edge-to-edge and the card's
`rounded-2xl` corners read clean; anything else leaves a `bg-gray-100` /
`dark:bg-gray-800` letterbox bar with a hard rectangular seam inside the
rounded card. Measured against every avatar's actual dimensions, aspect ratio
alone predicted the effect exactly — e.g. `ssneider.jpg` 1602×2156 (ratio
0.743, worst offender) down to `paula.jpg` 1408×1400 (ratio 1.006, barely
visible).

**Changed both occurrences of `object-contain` → `object-cover`** in this
block only (line-for-line diff otherwise). `object-cover` center-crops any
aspect ratio to fill the square, so no more seam regardless of source shape —
verified by screenshot (§8.12 recipe) across the full range, including the two
tallest portraits (`raul.jpg` 1200×1599, `ssneider.jpg` 1602×2156): both crop
to a clean headshot with no awkward framing, since `object-center` was already
the anchor.

**Trade-off, so it's a documented choice and not a silent one:** this crops
rather than shows the whole photo. Fine for portraits centered on a face (all
20 here); would cut off a group photo or an off-center subject. If a future
avatar looks wrong here, center-crop *that* file to square rather than
reverting this override — reverting brings back the letterbox seam for
everyone else.

**Noticed in passing, resolved by inspection:** `arianna`'s card shows a
generic silhouette. Not a bug — `assets/media/authors/arianna.webp` **is**
that silhouette. Confirmed by tracing the pipeline (`resources.GetMatch`
finds it, `get_author_profile` returns it as `.avatar`, `.Fit` processes it,
the `<img>` renders it) and by decoding the processed output: a real,
valid, 600×600 stock placeholder graphic, correctly resolved and cropped
throughout. She just never uploaded a photo. Content fix — a real
`arianna.<ext>` — not a template one.

### Card excerpt: prefer `short_bio`, never raw `bio`

Same block, a second fix. The stock card prints `$profile.bio` raw, clamped
to 2 lines by CSS (`line-clamp-2`) — no `markdownify`. `bio` in this site's
data is the full biography (headings, lists, several paragraphs), meant for
the profile page, not a 2-line card excerpt: rendered here it showed literal
`# ...` / `* ...` markdown syntax on anyone whose bio opens with a heading —
most of Past Lab Members.

Fixed the same way `page_author_card.html` (the publication-byline card,
"Author cards — short bio" above) already handles it: prefer `short_bio`,
and **deliberately no fallback to `bio`** — an author
with no `short_bio` shows no excerpt at all, matching that card's behaviour
and the old Academic v4 site's (its card used the short `bio` TOML field,
empty for some people). `get_author_profile` doesn't pass `short_bio`
through, so the fix reads it from `$authors` — the raw `get_authors_data`
map this block already has in scope — rather than re-fetching it.

`short_bio` **is** markdownified here (`emojify` too), unlike the old raw
`bio` print — a one-liner shouldn't need it, but it costs nothing and keeps
the two card types (`page_author_card.html`, `team-showcase`) consistent.

Verified per-slug against the raw data (temporary `warnf` dump, removed
before committing): every author's short excerpt matches their own
`short_bio`; `aleacker` and `mercedes` (no `short_bio` set) show no excerpt,
not a stray value borrowed from someone else's card — a first pass at
verifying this by scanning forward for the next `line-clamp-2` in the HTML
gave a false positive for exactly that reason (landed on the *next* card's
paragraph), corrected by scoping the check to each card's own boundary.

### Play on role/affiliations, not just headings

`--hb-font-heading` (Play) is wired to exactly one selector in the module's
CSS: `h1,h2,h3,h4,h5,h6`. Person names on the People grid and the profile
page *are* an `<h3>`/`<h1>`, so they already got Play with no override
needed. **Role and affiliation text do not** — both are plain `<div>`/`<p>`
elements with only colour/size utility classes, so they silently fell back
to `--hb-font-body` (Open Sans). Matches the Academic v4 site, which set
these fields in the heading face to read as structured identity (name,
title, org), distinct from free-text prose.

Fixed by adding the literal Tailwind v4 arbitrary-value utility
`font-[family-name:var(--hb-font-heading)]` directly to each role/affiliation
element, in three places:

- `_partials/hbx/blocks/team-showcase/block.html` — the People-grid card
  (both layout variants), on `$roleText` and `$first_affiliation`.
- `authors/term.html` — the individual profile page (new override, otherwise
  verbatim), on role and every affiliation link.
- `_partials/page_author_card.html` — the publication-byline card, on role
  only (this card doesn't show affiliations).

No new CSS file or `:root` variable needed — Tailwind's JIT scanner picks up
the class because it's written literally in each template (not built from a
variable), the same "scanner safety" rule the Preact block components already
follow. Verified compiled (`.font-\[family-name\:var\(--hb-font-heading\)\]{font-family:var(--hb-font-heading)}`
present in the built CSS) and applied on all three surfaces in the built HTML.

Could not confirm by screenshot in the first pass — Windows-Chrome interop
(§8.12's recipe) failed with `binfmt_misc` reporting no registered
interpreter, a different failure from the earlier documented ones. Verified
by direct CSS/HTML inspection instead — correctly, as far as it went: the
CSS mechanism (`--hb-font-heading` set un-layered at `:root`, beating
Tailwind's own `@layer theme` default) really does work. What that pass
missed was a fourth block never checked, caught only once a real screenshot
arrived.

#### The follow-up: `resume-biography`'s name is *never* a real heading

A user-supplied screenshot (`localhost:1313` vs. live `trypanosomatics.org`)
showed the "Trypanosomatics" org name on the homepage "About" card still in
the body face, disproving "usernames already get Play" as a blanket claim.
Root cause: `blox/resume-biography/block.html`'s name field only renders as
`<h1>` when `name_pronunciation` is set (a ruby-annotation feature for
phonetic name glosses); otherwise — every single profile in this dataset,
nobody sets that field — it renders as a plain `<div class="text-3xl
font-bold ...">`. Same gap as role/affiliation, different block, so it slid
past the audit that covered `team-showcase`, `authors/term.html` and
`page_author_card.html`.

Fixed the same way, in a fourth new override,
`_partials/hbx/blocks/resume-biography/block.html`: added
`font-[family-name:var(--hb-font-heading)]` to both the `<h1>` and `<div>`
name branches (belt-and-suspenders — the `<h1>` branch would already inherit
Play, but nothing currently exercises it) and to the affiliation wrapper.
`role` on this block *is* a real `<h3>` already and needed no change.

**Lesson for next time:** "the CSS mechanism resolves correctly" and "every
place that mechanism is supposed to apply actually does" are two different
claims — verifying the first doesn't establish the second. Enumerating every
block that renders a name/role/affiliation (`grep -rl` for `get_author_profile`
across `layouts/`) would have caught this without needing the screenshot.

### Section titles: mostly already headings, one wasn't — plus the navbar

Two follow-up questions after the name/role/affiliation fixes: do "Recent
Posts" / "Featured Publications" / "Recent & Upcoming Talks" need the same
per-block treatment, and is there a *global* switch instead of one-off fixes?

**Audited every block title on the homepage.** `team-showcase` ("This is
Us"), `tag-cloud` ("Popular Topics"), `portfolio` ("Projects"), `contact-info`
("Contact") all already render their title as a real `<h2>` — no fix needed,
they were never the problem. **Exactly one wasn't:** `content-collection` —
the block behind Recent Posts, Featured Publications, Recent & Upcoming
Talks, *and* the landing-page publications list — used a plain `<div
class="mb-6 text-3xl font-bold ...">`. One block, reused four times on this
page, so one fix (`<div>` → `<h2>`, same classes) covers all four section
titles at once — not four separate overrides.

**So yes, there is a global mechanism — `h1,h2,h3,h4,h5,h6{font-family:
var(--hb-font-heading)}` — and it already covers every genuine heading.**
Every per-element fix in this file so far (role, affiliation, the
`resume-biography` name, this collection title) was needed only because that
*specific* element wasn't a real heading tag upstream, not because the global
rule has any gap. Nothing here calls for a broader CSS selector or a new
`:root` override.

**Navbar text was a different, genuinely global gap.** `--hb-font-nav`
exists for exactly this — declared in the font pack, defaulting to
`var(--hb-font-heading)` — but the module never writes a rule that consumes
it (`.nav-link` etc. set colour/weight only). Identical shape to the already-
documented `--hb-font-size-base` gap in `STYLING.md` §5. Fixed with one CSS
rule there, not a template override: `.nav-link, .nav-dropdown-link,
.navbar-brand { font-family: var(--hb-font-nav); }`. This one **is** the
single global switch the navbar needed — covers the top bar, dropdowns, and
the site-title brand link in one place, no per-page template touched.

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
