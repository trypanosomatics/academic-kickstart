# Styling guide

Where to change what, cheapest option first. If a change can be made at level 1,
don't make it at level 4.

| # | Level | File | Use for |
|---|---|---|---|
| 1 | Design tokens | `data/themes/tryps.yaml`, `data/fonts/tryps.yaml` | colours, typefaces |
| 2 | Global knobs | `config/_default/params.yaml` | radius, density, header/footer variant, avatar shape |
| 3 | Per-section | `content/_index.md` | one section's view, columns, padding, background |
| 4 | Site CSS | `hugo-blox/blox/site/style.css` | anything the above can't reach |
| 5 | Template override | `layouts/…` | markup changes only — read `OVERRIDES.md` first |

**How it fits together:** tokens (1–2) are rendered into `--hb-*` CSS custom
properties in an inline `<style>` on every page. Tailwind v4 utilities and the
module's component CSS consume those variables. So changing a token restyles the
whole site without touching CSS.

Rebuild after any change: `hugo --gc`, or `pnpm dev` for live reload.

---

## 1. Colours — `data/themes/tryps.yaml`

Light and dark are separate blocks. Every value is a hex colour.

```yaml
hugoblox:
  light:
    colors: {primary, secondary}
    surfaces:
      background, foreground
      header: {background, foreground}
      footer: {background, foreground}
  dark:
    …same shape…
```

- `primary` drives links, buttons, accents (`text-primary-600`, `bg-primary-*`).
  Hugo Blox generates a full tint/shade scale from the one hex value.
- `surfaces.background` / `foreground` are the page body.
- `surfaces.header` is the **navbar**; `footer` the site footer.

Current values are documented in comments at the top of that file.

> **Do not** re-enable `hugoblox.header.theme_picker`. It inlines all twelve
> stock packs (~95 KB per page) and lets a visitor's `localStorage` override
> your palette. See `MIGRATION.md` §8.8.

## 2. Typefaces — `data/fonts/tryps.yaml`

```yaml
families: {heading: Play, body: Open Sans, code: PT Mono}
weights:  {heading: [400,700], body: [400,600,700], code: [400]}
leading:  {heading: 1.2, body: 1.6, code: 1.5}
tracking: {heading: "0", body: "0"}
variable: {heading: false, body: false, code: false}
```

Fonts load from Google Fonts in one request. **Two traps** (both bit us — see
`OVERRIDES.md`):

1. Multiple weights on a non-variable family need `;` not `,` in the URL.
   Patched in `layouts/_partials/functions/typography.html`.
2. `variable: true` emits the range `100..900`, which Google rejects for fonts
   whose axis is narrower (Open Sans is `300..800`) and then silently drops the
   family. Prefer `variable: false` with explicit weights unless you've checked
   the real axis.

After changing fonts, verify the request actually succeeds:

```bash
hugo --gc
URL=$(grep -oE 'https://fonts.googleapis.com/css2[^"]+' public/index.html | head -1 | sed 's/&amp;/\&/g')
curl -s -o /dev/null -w '%{http_code}\n' "$URL"          # 200
curl -s "$URL" | grep -oE "font-family: *'[^']*'" | sort -u   # every family listed
```

## 3. Global knobs — `config/_default/params.yaml`

Under `hugoblox:`

| Key | Values | Effect |
|---|---|---|
| `layout.radius` | `none` `sm` `md` `lg` `full` | corner rounding everywhere (`--hb-radius`) |
| `layout.spacing` | `compact` `comfortable` `spacious` | vertical rhythm (`--hb-spacing-base`, `--hb-spacing-section`) |
| `layout.avatar_shape` | `circle` `square` `rounded` | author avatars |
| `typography.pack` | filename in `data/fonts/` | which font pack |
| `theme.pack` | filename in `data/themes/` | which colour pack |
| `theme.mode` | `light` `dark` `system` | default mode |
| `theme.colors.*` | hex | override the pack's primary/secondary without editing it |
| `header.style` | `navbar` `navbar-simple` `minimal` | header variant |
| `header.sticky`, `header.align` | bool, `left/center/right` | header behaviour |
| `footer.style` | `minimal` `columns` `centered` | footer variant |

`layout.spacing` is the single biggest lever on "how much air the page has" —
try it before hand-tuning section padding.

## 4. Per-section — `content/_index.md`

Each landing-page section takes `content:` (what it shows) and `design:` (how).

**Size of the publication boxes on the home page** — the `#featured` section:

```yaml
  - block: collection
    id: featured
    design:
      view: article-grid   # article-grid | card | citation | date-title-summary | slides-gallery
      columns: 2           # 1 | 2 | 3 — fewer columns = bigger boxes
```

`view` is the biggest visual lever: `citation` is a dense text list,
`card` is boxed with images, `article-grid` is a picture grid.

**Design options available on every block** (handled by `parse_block_v3`):

```yaml
    design:
      css_class: ""                 # extra classes on the <section>
      css_style: ""                 # inline CSS on the <section>
      spacing:
        padding: ["6rem", "0", "6rem", "0"]   # top right bottom left
      background:
        color: "#f7f7f7"            # flat colour  → box/section background
        gradient: {start, end, angle}
        gradient_mesh: {enable: true}
        image: {filename, size, position, repeat, parallax}
        video: {path, flip}
        text_color_light: true      # light text over a dark background
        css_class: ""               # classes on the background layer
```

`background.image.filename` resolves from **`assets/media/`**, not `static/`.

Blocks available: `hero, resume-biography, resume-biography-3, resume-experience,
resume-skills, resume-awards, resume-languages, collection, portfolio, gallery,
team-showcase, contact-info, map, markdown, features, focus-areas, logos, stats,
steps, faq, testimonials, tech-stack, comparison-table, pricing, cta-card,
cta-button-list, cta-image-paragraph, search-hero` — plus this site's own
`tag-cloud` in `hugo-blox/blox/all-access/`.

Section list pages (`/publications/`, `/blog/`, `/events/`) take their view from
their own front matter, e.g. `content/publications/_index.md` → `view = "citation"`.

## 5. Site CSS — `hugo-blox/blox/site/style.css`

Concatenated into the Tailwind entry by the module, so Tailwind directives
(`@apply`, `theme()`, variants) work. Mounted via `config/_default/module.yaml`.
Use it for anything the layers above can't express.

**Content width.** Article bodies and page footers use `.max-w-prose`; blocks use
`max-w-3xl` / `max-w-5xl` / `max-w-7xl` depending on the block. To widen reading
columns site-wide:

```css
.max-w-prose { max-width: 78ch; }
```

**Base font size is set here, not in the font pack.** The module declares
`--hb-font-size-base` but **no rule consumes it** (checked in blox
`v0.0.0-20260527025321`), so `typography.sizes.base` has no effect. Tailwind's
whole scale is rem-based, so set the root instead — the same lever Academic v4
pulled (`html{font-size:18px}` above 58em):

```css
@media screen and (min-width: 58em) { html { font-size: 18px; } }
```

**Useful `--hb-*` variables** to override on `:root` (or `.dark`):

```
--hb-color-header-bg      --hb-color-header-fg
--hb-font-heading         --hb-font-body        --hb-font-code   --hb-font-nav
--hb-font-size-base       --hb-font-weight-heading    --hb-font-weight-body
--hb-font-leading-heading --hb-font-leading-body
--hb-font-tracking-heading --hb-font-tracking-body
--hb-radius               --hb-spacing-base     --hb-spacing-section
--hb-cols
```

Site-wide background and foreground come from the theme pack (level 1), not from
a variable you should override here.

## 6. Template overrides — `layouts/`

Only when the markup itself must change. Every override is a copy of an upstream
file that must be re-merged when the module is upgraded, so **read `OVERRIDES.md`
first** — it lists what is currently overridden, from which module version, and
exactly what was changed.

Views live in `layouts/_partials/views/` (`article-grid`, `card`, `citation`,
`date-title-summary`, `slides-gallery`); of these only `citation.html` is
currently overridden, to add the research-metrics badges.

> `layouts/` is a template directory: Hugo parses **every** file in it. Never put
> documentation there — a `.md` file containing Go template examples will fail
> the build.

---

## Recipes

| Want | Do |
|---|---|
| Navbar colour | `data/themes/tryps.yaml` → `light.surfaces.header.background` (and `dark.…`) |
| Page background, dark mode | same file → `dark.surfaces.background` |
| Bigger/smaller publication boxes on the home page | `content/_index.md` → `#featured` → `design.columns`, `design.view` |
| Denser publication list | `#publications` → `design.view: citation` |
| Wider article text | `hugo-blox/blox/site/style.css` → `.max-w-prose{max-width:…}` |
| Alternating section backgrounds | per section → `design.background.color` |
| Less whitespace overall | `params.yaml` → `hugoblox.layout.spacing: comfortable` |
| One section's padding | that section → `design.spacing.padding` |
| Rounder / squarer corners | `params.yaml` → `hugoblox.layout.radius` |
| Square avatars | `params.yaml` → `hugoblox.layout.avatar_shape` |
| Hero height | `#hero` → `design.size`: `compact` `default` `tall` `viewport` `none` |
| Hero banner image | `#hero` → `design.background.image.filename` (file in `assets/media/`) |
| People grouping and order | `#people` → `content.user_groups`, `content.sort_by` |
| Overall text size | `hugo-blox/blox/site/style.css` → root `font-size` (see above); 18px matches the old site |
| Page-title weight | same file → `h1[data-pagefind-meta="title"]` (Hugo Blox applies `font-bold`; old site used 500 → Play 400) |
| Hide "N min read" | `cascade.reading_time = false` in the section's `_index.md` — it is a **page** param, not a site setting |
| Navbar logo | `assets/media/logo.png` (or `logo.svg`, preferred). Auto-detected; `hugoblox.header.show_logo` defaults to true |
| Favicon | `assets/media/icon.png` |
| Author card one-liner | `short_bio:` in `data/authors/<slug>.yaml` (`bio:` is the long profile-page biography) |
| Badge size/alignment | CSS in `layouts/_partials/hooks/head-end/research-metrics.html` (`.hb-metrics`) |

## Gotchas

- **Tailwind only emits classes it can see.** Utilities written into templates or
  content are picked up via `hugo_stats.json`. Classes assembled at runtime by
  JavaScript are not — style those in `site/style.css` instead.
- **Vendor-injected markup can't take Tailwind classes.** The Altmetric and
  Dimensions badges don't exist until their scripts run, which is why they're
  styled with plain CSS in the head-end hook.
- **A stale `data-theme-pack` in `localStorage` overrides everything.** If colours
  look wrong in one browser only: `localStorage.removeItem('hb-theme-pack')`.
- **Hard-reload after CSS changes** — the stylesheet is fingerprinted in
  production but not in `hugo server`.
