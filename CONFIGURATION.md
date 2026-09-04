# Configuration

Where every setting lives now, and where it used to live in the Academic v4
`config/_default/params.toml`.

**The shift to understand:** `params.toml` held *both* site settings and widget
content — the map coordinates and the contact address sat next to the theme
name. In Hugo Blox, blocks own their own content. So the old file split in two:

| | |
|---|---|
| Site-wide settings | `config/_default/params.yaml`, all under one `hugoblox:` key |
| Anything that was a **widget** setting | `content/_index.md`, on the block itself |

Two data files carry the design tokens: `data/themes/tryps.yaml` (colours) and
`data/fonts/tryps.yaml` (typefaces). See `STYLING.md` for those.

Run `hugo --gc` after any change; `pnpm dev` reloads automatically.

---

## The config directory

| File | Holds |
|---|---|
| `hugo.yaml` | Hugo itself: `baseURL`, taxonomies, output formats, markup, security |
| `params.yaml` | Everything under `hugoblox:` — identity, theme, analytics, header/footer, … |
| `menus.yaml` | Navigation. Anchors **must** be written `/#id`, not `#id` (see below) |
| `module.yaml` | Hugo modules to import, and local mounts |
| `languages.yaml` | Language codes. Single-language site; mostly untouched |

---

## Common tasks

### Google Analytics

`config/_default/params.yaml`:

```yaml
hugoblox:
  analytics:
    google:
      measurement_id: "G-WDE728FHFE"   # GA4 property, stream 3466175922
```

Alternatives already stubbed alongside it: `google_tag_manager.container_id`,
`plausible.domain`, `fathom.site_id`, `pirsch.site_id`, `clarity.project_id`,
`baidu.site_id`. Set one, leave the rest empty.

`privacy.anonymize_analytics` (default `true`) adds `anonymize_ip`.

> The old site served `UA-1674362-6` — Universal Analytics, reaching GA4 only
> through Google's connected-tag bridge. It now reports to GA4 directly.

### The map

**Not in config.** It is part of `content/_index.md`.

Currently a **Google Maps embed** on the `contact-info` block:

```yaml
      map_embed: |-
        <iframe src="https://www.google.com/maps/embed/v1/place?key=…&q=LAT,LNG&zoom=15" …></iframe>
      map_url: 'https://www.google.com/maps/search/?api=1&query=LAT,LNG'
```

`map_embed` is **raw HTML**, not a URL — the block renders it through
`safeHTML`, so it must be a complete `<iframe>`.

Two Google Cloud console settings this depends on:

1. The key's API restrictions must include **Maps Embed API**. The iframe does
   not use the Maps JavaScript API, so a key restricted to that alone is
   rejected.
2. Referrer restrictions cover the production domains, so the map is **blank on
   `localhost:1313`**. Add `http://localhost:*` to the key's referrer list if
   you want it during local development.

Keep the `referrerpolicy="no-referrer-when-downgrade"` attribute — Google
matches the referrer restriction on the header the iframe sends, and a stricter
policy sends none, which fails the check.

**Commented alternative:** the Hugo Blox `map` block (MapLibre GL +
OpenFreeMap), directly below in the same file. No API key, no Google tracking,
works on localhost. To switch back, uncomment it and drop `map_embed`/`map_url`.

### Contact details

Also **not in config** — the `contact-info` block in `content/_index.md` carries
`email`, `phone`, `address`, `office_hours`, `social`, `show_form`.

> The street address appears in the `contact-info` block and the coordinates in
> the `map` block. Moving the lab means editing **both**.

### Site name, description, social

```yaml
hugoblox:
  identity:
    name: "Trypanosomatics Lab"
    organization: "Trypanosomatics"
    type: organization          # person | organization | local_business
    tagline: "A Trypanosome in the Shell"
    description: "…"            # meta description / social sharing
    social:
      twitter: "trypanosomatics"
```

### Navigation

`config/_default/menus.yaml`. Landing-page anchors **must** be `/#people`, never
`#people` — a bare fragment resolves against the current page, so from a
publication page it would just append to that URL. Details in `MIGRATION.md` §8.10.

Each `url: '/#id'` must match the `id:` of a block in `content/_index.md`.

### Section listing style

Per section, in its `_index.md` — e.g. `content/publications/_index.md`:

```toml
view = "citation"   # article-grid | card | citation | date-title-summary | slides-gallery
```

On the landing page it is per block instead: `design.view`. This replaces the
old `[projects] post_view / publication_view / talk_view` numbers.

---

## Full mapping from `params.toml`

| Old key | Now |
|---|---|
| `[marketing] google_analytics` | `params.yaml` → `analytics.google.measurement_id` |
| `[map] engine`, `api_key`, `zoom` | `content/_index.md` → `map_embed` on the `contact-info` block (Google), or the commented `map` block (MapLibre, keyless) |
| `email`, `phone`, `address`, `coordinates`, `directions`, `office_hours`, `appointment_url`, `contact_links` | `content/_index.md` → `contact-info` and `map` blocks |
| `[projects] post_view`, `publication_view`, `talk_view` | per block `design.view`, or `view` in the section `_index.md` |
| `theme = "tryps"` | `theme.pack` + `data/themes/tryps.yaml` |
| `day_night = true` | `theme.mode` — `light` \| `dark` \| `system` |
| `font`, `font_size` | `typography.pack` + `data/fonts/tryps.yaml` |
| `site_type`, `org_name`, `description`, `twitter` | `identity.*` |
| `main_menu = {align, show_logo}` | `header.align`, `header.show_logo` |
| `date_format`, `time_format`, `address_format` | `locale.*` |
| `math`, `diagram` | `content.math.enable`; diagrams need no flag — ```mermaid fences render via the module's code-block hook |
| `highlight` | `hugo.yaml` → `markup.highlight` (Hugo's own Chroma) |
| `[publications] citation_style` | `content.citations.style` |
| `[publications] date_format` | `locale.date_format` |
| `reading_time` | `content.reading_time.enable` — **but see the trap below** |
| `[avatar] shape` | `layout.avatar_shape` |
| `[avatar] gravatar` | no equivalent; avatars come from `assets/media/authors/<slug>.*` |
| `[search] engine` | `search.enable` (Pagefind) + `header.search` for the navbar icon |
| `[comments] engine` | `comments.enable` + `comments.provider` (`giscus` \| `disqus`) |
| `privacy_pack` | `privacy.enable`, `privacy.anonymize_analytics` |
| `edit_page = {repo_url, …}` | `repository.url`, `.branch`, `.content_dir`, `.enable` |
| `sharing_image` | per-page `image:`; site default from `identity`/`seo` |
| `[address_formats]` | supplied by the module — deleted |
| `link_authors` | **gone.** Authors always link when a profile exists in `data/authors/` |
| `section_pager`, `docs_section_pager` | **gone.** No equivalent |
| `plugins_js` | **gone.** Use a hook in `layouts/_partials/hooks/` — see `OVERRIDES.md` |

---

## Traps

**`reading_time` cannot be set site-wide.** The module gates on the *page*
param `.Params.reading_time`, so `content.reading_time.enable` in `params.yaml`
does nothing on its own. It is switched off for metadata-only pages by cascading
from the section index:

```toml
# content/publications/_index.md, content/events/_index.md
cascade.reading_time = false
```

**TOML tables absorb everything after them.** In a `+++` file, a `[header]` or
`[cascade]` section header swallows every subsequent top-level key into that
table. Use dotted keys (`cascade.reading_time = false`,
`publication.name = "…"`) or place the table header last. This silently
corrupted files twice during the migration.

**Do not add a `permalinks:` block to `hugo.yaml`.** The upstream starters
rewrite `/authors/` → `/author/` and `/tags/` → `/tag/`, which would break every
taxonomy URL the site has published.

**Do not re-enable `header.theme_picker`.** It inlines all twelve stock theme
packs into every page (~95 KB) and lets a visitor's `localStorage` override the
site palette. `MIGRATION.md` §8.8.

---

## See also

- `STYLING.md` — colours, fonts, layout, per-block design
- `OVERRIDES.md` — local template overrides and how to upgrade them
- `MIGRATION.md` — decision record and the reasoning behind these choices
