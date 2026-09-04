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

**Not in config.** It is a block in `content/_index.md`:

```yaml
  - block: map
    id: map
    content:
      location:
        lat: -34.579239
        lng: -58.525103
        address: |-
          Instituto de Investigaciones Biotecnológicas (IIB)
          25 de Mayo 1401, 1st Floor
          B1650HMP San Martín, Buenos Aires, Argentina
      zoom: 15
```

MapLibre GL + OpenFreeMap: **no API key and no `engine` setting**, which is what
the old `[map] engine = 1 / api_key` was for. To move the pin or change zoom,
edit this block.

A Google Maps embed alternative is documented in comments directly below it.
That route needs a Maps JavaScript API key, which is public by design (it ships
in the page HTML); protect it with referrer + API restrictions and a billing
budget rather than treating it as a secret. The lab's old key is unused now —
see `MIGRATION.md` §8.11.

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
| `[map] engine`, `api_key`, `zoom` | `content/_index.md` → `map` block (no key needed) |
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
