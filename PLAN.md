# Migration Plan — Trypanosomatics Lab Website

**Goal:** move off the frozen Academic v4 / Hugo 0.69.2 stack onto a supported,
modern-Hugo stack **without changing how the site looks or what it does** —
same widgets in the same order, same taxonomies, same multi-author pages, same
cross-linking between publications and author profiles, same URLs.

**Status:** proposal. Nothing in this document has been executed.

---

## 1. Where we are today (verified against the working tree)

| Item | Current value |
|---|---|
| Hugo | `0.69.2` extended, pinned in `netlify.toml` and the README |
| Theme | `themes/academic` — **git submodule**, `gcushen/hugo-academic` @ `c5b26892` (`v4.0.0-342`), `data/academic.toml` reports `version = 4.7.0`, `min_version = 0.62` |
| Config | `config/_default/{config,params,menus,languages}.toml` |
| Content | 179 files: 33 publications, 20 author profiles, 10 talks, 8 projects, 4 posts, 16 home widgets |
| Published URLs | 256 (`public/sitemap.xml`) |
| Custom appearance | `data/themes/tryps.toml`, `data/fonts/tryps.toml`, `assets/scss/custom.scss` |
| Template overrides | 5 files in `layouts/` (see §6) |
| Deploy | Netlify, `master` → <https://trypanosomatics.org/> |
| Local toolchain present | Hugo `0.123.7+extended`, Go `1.22.4`, Node `24.13.0` |

### 1.1 Home page — the visual contract to preserve

Eleven active sections, in this rendered order (verified in `public/index.html`):

`hero` (w3) → `about` (w20) → `slider` (w25) → `posts` (w60) → `featured` (w61)
→ `talks` (w62) → `projects` (w64) → `publications` (w66) → `tags` (w67)
→ `people` (w68) → `contact` (w130)

Inactive but present in the repo: `demo` (blank, w15), `skills` (featurette,
w30), `experience` (w40), `accomplishments` (w50).

### 1.2 Functionality that must survive

1. **Multi-author profile cards** at the bottom of every publication/talk/post —
   a card per lab member, not just the first author. Today this is a hand-patched
   `layouts/partials/page_author.html` (see §6.1).
2. **Author cross-linking** — `authors: ["@alejandro", "Morten Nielsen", …]`.
   The `@` is stripped by Hugo's `anchorize`, so `@alejandro` resolves to
   `content/authors/alejandro/`; plain names get an auto-generated taxonomy term
   page. ~150 such term pages exist today.
3. **Altmetric + Dimensions badges** on publication list items and single pages
   (3 template overrides + a `custom_js.html` script tag).
4. **People widget grouped by `user_groups`**, sorted by the per-author `weight`.
5. **Tag cloud**, **filterable project portfolio**, **image slider**,
   **Netlify contact form**, **built-in search**, **day/night toggle**.

### 1.3 Pre-existing defects worth fixing during the migration

| Defect | Evidence |
|---|---|
| Hero image never renders | `content/home/hero.md` sets `hero_media = "hero-academic.png"`; that file exists only in `themes/academic/exampleSite/static/img/`, which is not mounted. The rendered `<div class="hero-media">` is empty. |
| Dead analytics | `googleAnalytics = "UA-1674362-6"` — Universal Analytics stopped processing data in July 2023. |
| Exposed Maps key | `params.toml` commits a Google Maps API key in plaintext. Rotate it and restrict it by HTTP referrer. |
| Wrong "edit this page" repo | `edit_page.repo_url` points at `gcushen/hugo-academic`. |
| Malformed author lists | 7 files have unquoted or line-broken YAML flow sequences — currently tolerated, brittle. Listed in §7.3. |
| Dangling slide reference | `content/project/tdrtargets/index.md` has `slides = "example-slides"`; no such deck exists. |
| `.gitignore` vs `netlify.toml` | `netlify*` is ignored by pattern, but `netlify.toml` is already tracked. Harmless, but confusing — tighten the pattern. |

---

## 2. Target stack — decision

**Recommendation: Hugo Blox "Bootstrap" module (`blox-bootstrap/v5`), consumed as
a Hugo Module, on Hugo ≥ 0.135 extended.**

### 2.1 The three real options

| | **A. blox-bootstrap v5** *(recommended)* | **B. Tailwind `blox`** | **C. Vendor v4 into `layouts/`** |
|---|---|---|---|
| Module path | `github.com/HugoBlox/hugo-blox-builder/modules/blox-bootstrap/v5` | `github.com/HugoBlox/kit/modules/blox` | none |
| Latest | `v5.9.7` tag (Feb 2024); starters pin pseudo-version `v5.9.8-0.20241012174104-661cadc17327` | `v0.12.0` (Apr 2026), actively developed | n/a |
| Hugo requirement | `min: 0.123.3`, extended (declared in the module's `hugo.yaml`); upstream starter runs `0.135.0` | `0.162.0` + Node/pnpm + Pagefind | whatever we make work |
| Keeps our look | **Yes** — same Bootstrap 4 CSS, same theme/font data files | **No** — full redesign | Yes |
| Has our widgets | **All of them**: `hero, about.biography, slider, collection, portfolio, tag_cloud, people, contact, features, experience, accomplishments, markdown` + a `v1/` legacy-name shim | **No** — `blox/blox/` contains `hero, portfolio, gallery, map, contact-info, content-collection, team-showcase, markdown, features, stats, …` but **no `people`, no `tag_cloud`, no `slider`, no `featured`** | Yes |
| Section names | `post`, `publication`, `talk`, `project` still work | starter renames to `blog`, `publications`, `events`, `projects` | unchanged |
| Effort | Moderate (~2–4 days) | High (redesign + rebuild 3–4 missing blocks + URL changes) | High + permanent maintenance |
| Longevity | Frozen upstream (the `blox-bootstrap` directory has been removed from `HugoBlox/kit@main`; tags remain resolvable via the Go proxy, and its deps `blox-core v0.4.1` / `blox-seo v0.3.1` were still tagged in Aug 2025) | Actively developed | We own it forever |

### 2.2 Why A

The brief is *"same visual appearance and functionality … but all components up
to date and compatible with latest Hugo releases."* Option B satisfies "up to
date" but fails "same appearance" — it is a different design system with a
different block vocabulary and no people/tag-cloud/slider blocks. Option C
satisfies "same appearance" but is the opposite of "up to date."

Option A is the only one that does both: it is the direct, maintained-through-2024
descendant of the exact templates this site renders with, and it lifts the Hugo
floor from 0.69 to 0.123+ — a five-year jump that gets us off the pinned binary,
off git submodules, and onto the Hugo Modules workflow.

### 2.3 Being honest about longevity

`blox-bootstrap` is in maintenance-freeze. This migration is a **stabilisation**,
not a subscription to an actively developed theme. What it buys:

- current Hugo, current Go module tooling, no pinned 2020 binary;
- the theme is a versioned dependency, not a submodule that `git clone` can silently miss;
- our overrides shrink (one of the five disappears entirely — §6.1);
- a clean, documented base from which a later Tailwind migration is a
  *content-and-design* project rather than an archaeology project.

Treat a future move to the Tailwind `blox` module as a **separate, optional
project** (§11), to be decided on design grounds, not forced by breakage.

### 2.4 The do-nothing fallback

If this migration is deferred, at minimum containerise the build so it stops
depending on a hand-installed `hugo692`:

```dockerfile
FROM klakegg/hugo:0.69.2-ext
```

That is a stopgap, not a plan. Netlify's `HUGO_VERSION = "0.69.2"` will not be
honoured forever.

---

## 3. Phase overview

| Phase | What | Risk | Rollback |
|---|---|---|---|
| 0 | Baseline capture + branch | none | n/a |
| 1 | Toolchain: submodule → Hugo Module | low | `git checkout master` |
| 2 | Config translation (TOML → YAML) | medium | per-commit revert |
| 3 | Theme/font/SCSS data files | low | per-commit revert |
| 4 | Media relocation (`static/img` → `assets/media`) | low | per-commit revert |
| 5 | Home page: legacy widgets → v2 landing sections | medium | Phase 5a is a working checkpoint |
| 6 | Re-apply template overrides | medium | per-commit revert |
| 7 | Content front matter normalisation | medium | per-commit revert |
| 8 | Verification against baseline | none | n/a |
| 9 | Deploy | low | Netlify instant rollback |

All work happens on a branch: `migrate/hugoblox-v5`. `master` stays deployable
throughout.

---

## 4. Phase 0 — Baseline capture

Before touching anything, record what "unchanged" means.

1. Build the current site with the pinned binary into a reference directory:
   ```bash
   hugo692 --gc --destination ../baseline-public
   ```
2. Freeze the **URL contract** — this is the single most important artefact:
   ```bash
   grep -o '<loc>[^<]*</loc>' ../baseline-public/sitemap.xml \
     | sed 's/<[^>]*>//g' | sort > baseline-urls.txt   # expect 256 lines
   ```
3. Capture reference screenshots at 1440px and 390px widths for: home page
   (full scroll), one publication, one talk, one project, one author profile,
   `/publication/`, `/tags/`, `/authors/fernan/`, and both day and night mode.
4. Snapshot rendered author cross-links for spot-checking later:
   ```bash
   grep -rho 'href="/authors/[^"]*"' ../baseline-public | sort | uniq -c > baseline-authorlinks.txt
   ```
5. `git checkout -b migrate/hugoblox-v5`

**Exit criterion:** `baseline-urls.txt`, screenshots, and author-link counts are
committed to a scratch location (not the site content).

---

## 5. Phases 1–4 — Toolchain, config, appearance, media

### 5.1 Phase 1 — Hugo Modules

```bash
# Remove the submodule
git submodule deinit -f themes/academic
git rm -f themes/academic
rm -rf .git/modules/themes/academic
git rm -f .gitmodules update_academic.sh page_author.html.patch

# Initialise the module
hugo mod init github.com/trypanosomatics/academic-kickstart
```

New `config/_default/module.yaml`:

```yaml
imports:
  - path: github.com/HugoBlox/hugo-blox-builder/modules/blox-bootstrap/v5
  - path: github.com/HugoBlox/hugo-blox-builder/modules/blox-plugin-netlify
```

Then `hugo mod get -u` and commit `go.mod` + `go.sum`. **Pin the version** —
either the tag `v5.9.7` or the pseudo-version the upstream research-group starter
uses, `v5.9.8-0.20241012174104-661cadc17327`. Do not float.

Install Hugo extended **0.135.0** locally (matching what upstream tests against)
and update `netlify.toml`:

```toml
[build]
  command = "hugo --gc --minify -b $URL"
  publish = "public"

[build.environment]
  HUGO_VERSION = "0.135.0"
  GO_VERSION   = "1.21.5"
  HUGO_ENABLEGITINFO = "true"

[context.deploy-preview]
  command = "hugo --gc --minify --buildFuture -b $DEPLOY_PRIME_URL"

[[plugins]]
  package = "netlify-plugin-hugo-cache-resources"
```

> Deliberately conservative: 0.135.0 is the version upstream ships against, not
> the newest Hugo in existence. Bumping past it is a **follow-up** task with its
> own test cycle (§11), not part of this migration.

Also delete `view.sh`'s stale invocation or repoint it at plain `hugo server`.

### 5.2 Phase 2 — Config translation

Replace `config/_default/*.toml` with `hugo.yaml`, `params.yaml`, `menus.yaml`,
`languages.yaml`. `menus.yaml` and `languages.yaml` are near-mechanical
translations. The other two:

**`config.toml` → `hugo.yaml`**

| v4 | v5 | Note |
|---|---|---|
| `theme = "academic"` | *(delete)* | module system supplies it |
| `baseurl = "/"` | `baseURL: 'https://trypanosomatics.org/'` | set the real URL; Netlify's `-b $URL` overrides per-context |
| `paginate = 10` | `pagination:`<br>`  pagerSize: 10` | `paginate` is removed in modern Hugo |
| `googleAnalytics = "UA-…"` | move to `params.yaml` → `marketing.analytics.google_analytics` | replace with a GA4 `G-…` ID or leave empty |
| `disqusShortname` | `params.yaml` → `features.comment.*` | currently disabled; keep disabled |
| `[markup.highlight] codeFences = false` | `codeFences: true` | v5 uses Hugo's highlighter |
| `[taxonomies]` | unchanged | `tag`, `category`, `publication_type`, `author` |
| `[outputs]` `home = [HTML, RSS, JSON, WebAppManifest]` | keep; the netlify plugin adds `headers`/`redirects` | |
| `enableGitInfo`, `enableEmoji`, `ignoreFiles`, `[imaging]` | unchanged | |

> **Critical:** the upstream starter's `hugo.yaml` contains a `permalinks:` block
> that rewrites `/authors/` → `/author/`, `/tags/` → `/tag/`,
> `/publication_types/` → `/publication-type/`. **Do not copy it.** Adopting it
> would break every taxonomy URL in `baseline-urls.txt`. Omit the block entirely
> so Hugo's defaults reproduce today's paths.

**`params.toml` → `params.yaml`** — v5 regroups flat keys into namespaces:

| v4 flat key | v5 nested key |
|---|---|
| `theme = "tryps"` / `day_night = true` | `appearance.theme_day: tryps`, `appearance.theme_night: tryps` |
| `font`, `font_size` | `appearance.font`, `appearance.font_size` |
| `site_type`, `org_name`, `description`, `twitter` | `marketing.seo.*` |
| `main_menu = {align, show_logo}` | `header.navbar.{align, show_logo, show_day_night, show_search}` |
| `date_format`, `time_format`, `address_format` | `locale.*` |
| `highlight`, `math`, `diagram`, `privacy_pack` | `features.syntax_highlighter.enable`, `features.math.enable`, `features.privacy_pack.enable` |
| `edit_page = {repo_url, …}` | `features.repository.{url, content_dir, branch}` — **fix the URL to `trypanosomatics/academic-kickstart`, branch `master`** |
| `[avatar] gravatar/shape` | `features.avatar.{gravatar, shape}` |
| `[search] engine = 1` | `features.search.provider: wowchemy` |
| `[map] engine = 1, api_key` | `features.map.provider: google`, `features.map.api_key` — **rotate the key** |
| `[comments] engine = 0` | `features.comment.provider: ''` |
| `[publications]` | `publications.{date_format, citation_style}` — unchanged shape |
| `[projects] post_view / publication_view / talk_view` | unchanged |
| `email`, `phone`, `address`, `coordinates`, `directions`, `office_hours`, `appointment_url`, `contact_links` | move into the **contact block's own front matter** in v5, not `params` (§5.5) |
| `copyright` | `footer.copyright.notice` |
| `sharing_image` | `marketing.seo.*` / page-level image |
| `[address_formats]` | supplied by the module (`data/address_formats.toml`) — delete ours |

### 5.3 Phase 3 — Theme, fonts, SCSS

- `data/fonts/tryps.toml` — **no change needed**; the v5 schema is identical
  (`name`, `google_fonts`, `heading_font`, `body_font`, `nav_font`, `mono_font`,
  `font_size`, `font_size_small`).
- `data/themes/tryps.toml` — **must be rewritten.** v4 is flat with a
  `light = true` flag; v5 uses `[light]` and `[dark]` tables:

  ```toml
  name = "tryps"

  [light]
    primary          = "#69870E"
    menu_primary     = "#7DA211"
    menu_text        = "#024452"
    menu_text_active = "#2962ff"
    menu_title       = "#024452"
    home_section_odd  = "rgb(255, 255, 255)"
    home_section_even = "rgb(247, 247, 247)"

  [dark]
    # Currently unspecified. Either author a dark palette here, or set
    # appearance.theme_night to a stock dark theme, or disable the toggle
    # (header.navbar.show_day_night: false).
  ```
  **Open question for the site owner:** today `day_night = true` with a
  light-only theme. Decide whether night mode gets a real `tryps` dark palette,
  falls back to a stock theme, or is switched off. Compare against the baseline
  night-mode screenshots.
- `assets/scss/custom.scss` — **carries over unchanged**; v5's `main.scss` still
  does `@import "custom";`.

### 5.4 Phase 4 — Media relocation

v5 blocks resolve background/hero/slider images through
`resources.Get "media/<file>"`, i.e. **`assets/media/`**, and `errorf` if the file
is missing. v4 resolved them from `static/img/`.

```
static/img/tdrtargets-logo-v6-260x260.jpg  →  assets/media/
static/img/aprank-v1.png                   →  assets/media/
static/img/chagastope.png                  →  assets/media/
static/img/headers/*.jpg|png               →  assets/media/headers/
```

Rules:
- Anything referenced by a **block** (`hero.content.image.filename`,
  `slider [[item]] overlay_img`, `design.background.image`) → move to `assets/media/`.
- Anything referenced from **Markdown body text** as `/img/…` → leave in
  `static/img/` (moving it changes public URLs).
- `assets/images/{icon,logo}.png` — verify against v5's expected location for the
  navbar logo and site icon; adjust if the module expects `assets/media/icon.png`.
- **Fix the hero:** supply a real `assets/media/hero-academic.png` (or whatever
  image the lab wants) or drop `image` from the hero block. Note this is a
  *visible improvement*, so flag it explicitly rather than letting it look like
  an accidental diff against the baseline screenshots.

---

## 6. Phase 6 — Template overrides

Five overrides today. After migration: **four** — and one of them may become
unnecessary too.

### 6.1 `layouts/partials/page_author.html` — **DELETE**

This is the biggest single win. The current override is a hand-rolled hack
(credited in-file to `@eric-roca`) that wraps the theme's single-author box in
`range $.Params.authors` to render a card per author. It is fragile: it opens two
`range`/`with` blocks that only close at the end of the file, and it drifted from
the theme (uses `urlize` where the theme moved to `anchorize`, `class="portrait"`
where the theme moved to `class="avatar avatar-circle"`, and it lost the
`avatar.shape` support).

**v5 does this natively.** Its `page_author.html` is:

```gotemplate
{{ else if .Params.authors }}
  {{ range $author_obj := (.GetTerms "authors") }}
    {{ partial "page_author_card" (dict "author_page" $author_obj.Page) }}
  {{ end }}
{{ end }}
```

Delete both `layouts/partials/page_author.html` and the stale
`page_author.html.patch`. Verify against the baseline that every publication
still shows the same set of profile cards.

### 6.2 `layouts/partials/li_card.html` → `layouts/partials/views/card.html`

### 6.3 `layouts/partials/li_compact.html` → `layouts/partials/views/compact.html`

v5 renamed the list-item partials to `views/{card,citation,compact,list,masonry,showcase}.html`.
The Altmetric/Dimensions badge block ports **verbatim** — v5's views still use the
same `$item.Params.doi` variable. Procedure for each:

1. Copy the v5 module file into `layouts/partials/views/`.
2. Re-insert the badge block at the equivalent position (after the metadata line,
   before the summary).
3. Record the upstream version copied, in a comment at the top of the file.

### 6.4 `layouts/publication/single.html`

Same treatment: copy v5's `layouts/publication/single.html`, re-insert the
Altmetric donut row and Dimensions badge row. Note that v5 computes
`$pub_type_csl` / `$pub_type_display` at the top from **string** publication types
(§7.2) — do not carry the v4 numeric logic across.

### 6.5 `layouts/partials/custom_js.html` — **keep as-is**

Loads `altmetric embed.js`. v5 still honours the hook via
`site_js.html` → `{{ if templates.Exists "partials/custom_js.html" }}`, marked
*deprecated* but functional. Leave it; if it is ever removed upstream, the
replacement is a `head`/`footer` partial or `params.plugins_js`.

### 6.6 Override hygiene (new practice)

Add `layouts/OVERRIDES.md` recording, for each override: the upstream file it
was copied from, the module version, and the exact local delta. Without this, the
next upgrade repeats the archaeology this migration just did.

---

## 7. Phase 7 — Content migration

### 7.1 Front matter format normalisation

Currently mixed: 53 TOML (`+++`) files, 22 YAML (`---`) files.

| Section | TOML files | YAML files |
|---|---|---|
| `publication` | 24 | 9 |
| `authors` | 20 | 0 |
| `project` | 7 | 1 |
| `talk` | 1 | 9 |
| `post` | 1 | 3 |
| `home` | 16 | 0 |

Hugo supports both indefinitely, so this is **optional** — but recommended,
because all Hugo Blox documentation, archetypes, and examples are YAML, and the
inconsistency is a standing source of copy-paste errors. Convert everything to
YAML in **one dedicated commit per section** so review stays legible.

### 7.2 Publication types — **required**

v5 dropped numeric types for CSL strings. `layouts/publication/single.html` looks
up `i18n (printf "pub_%s" …)`, so `"2"` would render literally as *"2"*.

31 files affected: 29 with `["2"]`, 1 with `["3"]`, 1 with `["6"]`.

| v4 numeric | v5 CSL string | Renders as |
|---|---|---|
| `"0"` Uncategorized | *(omit the field)* | — |
| `"1"` Conference paper | `paper-conference` | Conference paper |
| `"2"` Journal article | `article-journal` | Journal article |
| `"3"` Preprint / Working paper | `article` | Preprint |
| `"4"` Report | `report` | Report |
| `"5"` Book | `book` | Book |
| `"6"` Book section | `chapter` | Book section |
| `"7"` Thesis | `thesis` | Thesis |
| `"8"` Patent | `patent` | Patent |

Two consequences to check:
- The `publication_types` **taxonomy URLs change** (`/publication_types/2/` →
  `/publication_types/article-journal/`). These appear in `baseline-urls.txt`.
  Either accept the change and add `aliases`, or add Netlify redirects. Decide
  before deploying.
- `content/home/featured.md` and any block filtering on `publication_type` must
  be updated to the new values.

### 7.3 Author list hygiene — **required**

Seven files have unquoted or line-broken YAML flow sequences. They parse today by
luck; quote every entry and put each list on one line:

```
content/talk/2022-SAP-TDR-Screening/index.md:26          unquoted: Valeria Tekiel
content/talk/2022-SAP-Chagas-Antigen-Epitope-Atlas/index.md:26  unquoted × 7
content/talk/2019-TDR/index.md:26                        unquoted × 5
content/talk/2019-SAP/index.md:26                        list broken across lines
content/talk/2018-ASTMH/index.md:27                      list broken across lines
content/publication/2020-UranLandaburu/index.md:6        stray leading space
content/publication/2019-SalasSarduy/index.md:5          stray leading space
```

The `@username` convention is **preserved** — v5 resolves authors through
`.GetTerms "authors"`, and Hugo still urlizes `@alejandro` to the `alejandro`
term, which is backed by `content/authors/alejandro/_index.md`. No content change
needed for cross-linking.

### 7.4 Author profiles — 20 files

| v4 | v5 |
|---|---|
| `name = "Fernán Agüero"` | `title: Fernán Agüero` |
| — | `first_name: Fernán` / `last_name: Agüero` (add; used for default sorting and SEO) |
| `weight = 10` | keep — but the People block's default sort is `Params.last_name`, so set `sort_by: Params.weight` explicitly (§7.5) to preserve today's order |
| `authors = ["fernan"]` | keep |
| `superuser`, `role`, `organizations`, `bio`, `email`, `interests`, `user_groups`, `education.courses`, `social` | unchanged shapes |
| — | `highlight_name: false` (optional) |

Note: two profiles currently set `superuser = true` (`fernan` and
`trypanosomatics`). v5 uses the superuser for the fallback author box and site
description — confirm which one should hold it.

### 7.5 Home page — Phase 5, staged

**Phase 5a (checkpoint): keep `content/home/*.md` as-is.**
blox-bootstrap v5 ships a legacy parser (`functions/parse_block_v1.html` +
`partials/blocks/v1/*`) that maps our widget names directly:

| our `widget =` | v5 block |
|---|---|
| `hero`, `contact`, `people`, `portfolio`, `slider`, `tag_cloud`, `experience`, `accomplishments` | same name |
| `about` | `about` (v1 shim) → `about.biography` |
| `blank` | `markdown` |
| `featurette` | `features` |
| `pages` | `collection` |
| `featured` | `collection` |

So Phase 5a should build and look right with only the media-path fixes from
Phase 4. **Commit here — this is the safe rollback point** and the natural place
to run the first full visual diff against the baseline.

**Phase 5b (target): convert to a v2 landing page.**
Replace the 16 `content/home/*.md` files with a single `content/_index.md`:

```yaml
---
title:
type: landing
sections:
  - block: hero
    content:
      title: The Trypanosomatics Laboratory
      image:
        filename: hero-academic.png
    design:
      background:
        gradient_start: '#4bb4e3'
        gradient_end:   '…'
  - block: about.biography
    content:
      title: About
      username: trypanosomatics
  - block: slider
    …
  - block: collection      # was widget = "pages", page_type = "post"
    content:
      title: Recent Posts
      count: 5
      filters: { folders: [post] }
    design: { view: compact, columns: '1' }
  - block: collection      # was widget = "featured"
    content:
      title: Featured Publications
      filters: { folders: [publication], featured_only: true }
  …
---
```

Ordering becomes list order rather than `weight`. The inactive widgets
(`demo`, `skills`, `experience`, `accomplishments`) are simply omitted — but keep
them in a commented block or an `archive/` directory if the lab wants them back.

Anchor IDs must be preserved: `menus.yaml` links to `#about`, `#posts`,
`#featured`, `#talks`, `#projects`, `#publications`, `#tags`, `#people`,
`#contact`. Set each section's `id:` explicitly to match.

### 7.6 Contact block

`email_form = 1` becomes:

```yaml
  - block: contact
    id: contact
    content:
      title: Contact
      email: info@trypanosomatics.org
      phone: '+54 11 4006-1500 exts 2110, 2120, 2107'
      address: { street: '25 de Mayo 1401', city: San Martín, region: Buenos Aires,
                 postcode: B1650HMP, country: Argentina, country_code: AR }
      coordinates: { latitude: '-34.579239', longitude: '-58.525103' }
      directions: Edificio IIB (Biotecnología), 1st Floor
      office_hours: ['Monday — Friday 9:00 to 19:00 ART']
      appointment_url: 'https://calendly.com/trypanosomatics'
      contact_links: [...]
      autolink: true
      form:
        provider: netlify
        netlify: { captcha: false }
```

The contact details move **out of `params.yaml`** and into the block.

---

## 8. Phase 8 — Verification

The migration is done when all of these pass. Nothing ships on "looks fine to me."

### 8.1 Build health
- [ ] `hugo --gc --printI18nWarnings --printPathWarnings` completes with **zero errors** and no new warnings.
- [ ] `hugo --templateMetrics` shows no missing-partial fallbacks.

### 8.2 URL parity — the hard gate
```bash
grep -o '<loc>[^<]*</loc>' public/sitemap.xml | sed 's/<[^>]*>//g' | sort > new-urls.txt
diff baseline-urls.txt new-urls.txt
```
- [ ] The only accepted differences are the `publication_types` taxonomy paths
      from §7.2, and each of those has an `aliases:` entry or a Netlify redirect.
- [ ] Every other one of the 256 baseline URLs resolves.

### 8.3 Cross-linking parity
- [ ] `grep -rho 'href="/authors/[^"]*"' public | sort | uniq -c` matches `baseline-authorlinks.txt`.
- [ ] Every publication page shows the **same number of author profile cards** as
      the baseline (this is the §6.1 regression risk).
- [ ] `/authors/fernan/` still lists the same publications, talks, and posts.
- [ ] A publication with mixed `@lab` and plain-name authors (e.g.
      `2021-ricci-aprank-frontiers`) links lab members to profiles and renders
      external co-authors as plain taxonomy terms, exactly as before.

### 8.4 Visual parity
Side-by-side against the Phase 0 screenshots, at 1440px and 390px, day and night:
- [ ] Home page: 11 sections, same order, same anchors, same section backgrounds
      (odd/even alternation from `tryps.toml`).
- [ ] Navbar: logo, `tryps` colours, menu order, day/night toggle, search icon.
- [ ] People section: same groups in the same order, same member order within
      each group, avatars circular, social icons present.
- [ ] Tag cloud: same tags, same relative sizing.
- [ ] Project portfolio: filter buttons work, same default filter.
- [ ] Slider: same slides, same overlay images, autoplay still disabled.
- [ ] Fonts: Play / Open Sans / PT Mono actually loading.

### 8.5 Feature checks
- [ ] Altmetric donut and Dimensions badge render on a publication single page
      **and** in list views (`view: compact` and `view: card`).
- [ ] Built-in search returns results.
- [ ] Contact form submits and appears in Netlify Forms (test on a deploy preview).
- [ ] RSS (`/index.xml`, `/post/index.xml`) validates.
- [ ] `/index.webmanifest` still emitted.
- [ ] `hugo --minify` output contains no `UA-` analytics snippet (or the GA4 one, if adopted).

### 8.6 Deploy
- [ ] Netlify **deploy preview** on the branch is green and passes §8.4/§8.5.
- [ ] Merge to `master`; watch the production build.
- [ ] Post-deploy: spot-check 10 URLs from `baseline-urls.txt` on the live site.

---

## 9. Rollback

- **Any phase:** `git revert` the phase commit; each phase is one commit.
- **Post-merge:** Netlify → Deploys → the last `master` build before the merge →
  *Publish deploy*. Instant.
- **Nuclear:** `master` before the merge still contains the submodule reference
  and `HUGO_VERSION = 0.69.2`; `git clone --recurse-submodules` of that commit
  reproduces today's site exactly.

Keep the branch and the baseline artefacts for at least one month after deploy.

---

## 10. Effort estimate

| Phase | Estimate |
|---|---|
| 0 — Baseline | 2 h |
| 1 — Toolchain | 2 h |
| 2 — Config | 3 h |
| 3 — Theme/fonts | 1 h (+ dark-palette decision) |
| 4 — Media | 1 h |
| 5a — Legacy-widget checkpoint | 2 h |
| 5b — Landing page conversion | 4 h |
| 6 — Overrides | 3 h |
| 7 — Content (31 pub types, 20 authors, 7 author lists, optional TOML→YAML) | 6 h |
| 8 — Verification | 4 h |
| 9 — Deploy | 1 h |
| **Total** | **~29 h ≈ 4 working days** |

The two riskiest phases are **6** (Altmetric/Dimensions badges must be re-derived
against unfamiliar upstream templates) and **7.2** (publication-type change is the
only one that moves public URLs).

---

## 11. After the migration

1. **Update the README.** Sections 1, 2, 6, and 7 are all about the pinned
   0.69.2 workflow and become wrong the moment Phase 1 lands. In particular
   remove *"Do not upgrade Hugo or the theme."*
2. **Add CI.** A GitHub Actions workflow that runs `hugo --gc --minify` on every
   PR turns future breakage into a red check instead of a broken deploy. This is
   the single highest-value follow-up.
3. **Hugo version bumps.** With CI in place, test 0.140 → 0.150 → latest as
   separate one-line PRs. `blox-bootstrap` declares only a *minimum* of 0.123.3;
   the practical ceiling is unknown and must be found empirically.
4. **Rotate the Google Maps API key** (§1.3) and restrict it by referrer.
5. **Analytics decision** — GA4, a privacy-preserving alternative, or nothing.
6. **Author-page noise** — ~150 taxonomy term pages exist for external
   co-authors with no profile. Consider `_build: {render: never}` for
   profile-less authors, or accept them. This is a content decision, not a
   migration blocker; it was the behaviour before too.
7. **The Tailwind question.** Revisit `github.com/HugoBlox/kit/modules/blox`
   (`v0.12.0`, actively developed) as a **redesign project** when the lab wants a
   new look. It requires: Node + pnpm + Pagefind in the build, rebuilding the
   people / tag-cloud / slider / featured blocks that do not exist there, and
   accepting the `post`→`blog`, `talk`→`events`, `publication`→`publications`
   section renames (with redirects). Estimate 3–4× this migration. Do not start
   it under time pressure.

---

## 12. Open questions for the site owner

1. **Night mode** — author a `tryps` dark palette, fall back to a stock dark
   theme, or turn the toggle off? (§5.3)
2. **Publication-type URLs** — accept `/publication_types/article-journal/` with
   redirects from `/publication_types/2/`, or preserve the numeric paths? (§7.2)
3. **Hero image** — supply a real image, or remove the hero image entirely?
   It has been silently broken. (§1.3, §5.4)
4. **Analytics** — GA4, something else, or drop it? (§1.3)
5. **Superuser** — `fernan` or `trypanosomatics`? (§7.4)
6. **Inactive widgets** — delete `demo`, `skills`, `experience`,
   `accomplishments`, or keep them parked? (§7.5)
7. **Front matter normalisation** — do the TOML→YAML sweep now, or leave the
   files mixed? (§7.1)

---

## Appendix A — Verified upstream facts

Everything below was checked against upstream sources while writing this plan,
not recalled.

| Fact | Source |
|---|---|
| `blox-bootstrap` requires Hugo ≥ `0.123.3` extended | `modules/blox-bootstrap/hugo.yaml` @ v5.9.7 |
| Upstream research-group starter runs Hugo `0.135.0` | `HugoBlox/theme-research-group/netlify.toml` |
| It pins `blox-bootstrap/v5 v5.9.8-0.20241012174104-661cadc17327` | `HugoBlox/theme-research-group/go.mod` |
| v5 blocks include `people`, `tag_cloud`, `slider`, `portfolio`, `collection`, `contact`, `hero`, `about.biography`, `features`, `experience`, `accomplishments`, `markdown`, plus a `v1/` legacy shim | `modules/blox-bootstrap/layouts/partials/blocks/` |
| The Tailwind `blox` module has **no** `people`, `tag_cloud`, `slider`, or `featured` block | `HugoBlox/kit/modules/blox/blox/` @ main |
| Tailwind `blox` latest is `v0.12.0` (2026-04-02); `academic-cv` builds it on Hugo `0.162.0` + pnpm + Pagefind | Go proxy `@latest`; `HugoBlox/theme-academic-cv/netlify.toml` |
| v5 `page_author.html` already loops all authors via `.GetTerms "authors"` | `modules/blox-bootstrap/layouts/partials/page_author.html` |
| v5 list views live at `partials/views/{card,compact,citation,list,masonry,showcase}.html` and still expose `$item.Params.doi` | `modules/blox-bootstrap/layouts/partials/views/` |
| `custom_js.html` / `custom_head.html` hooks still fire (marked deprecated) | `site_js.html:270`, `site_head.html:218` |
| Block background/hero/slider images resolve from `assets/media/` | `parse_block_v1.html:52`, `blocks/hero.html:67`, `blocks/slider.html:42` |
| Publication types are CSL strings; i18n ids are `pub_paper_conference`, `pub_article_journal`, `pub_article`, `pub_report`, `pub_book`, `pub_chapter`, `pub_thesis`, `pub_patent` | `modules/blox-bootstrap/i18n/en.yaml:177-199`; `layouts/publication/single.html:3-10` |
| v5 theme data files use `[light]` / `[dark]` tables | `modules/blox-bootstrap/data/themes/minimal.toml` |
| v5 font data files are schema-identical to v4 | `modules/blox-bootstrap/data/fonts/native.toml` |
| `assets/scss/custom.scss` is still imported | `modules/blox-bootstrap/assets/scss/main.scss:52` |
| Dependencies resolve on the Go proxy: `blox-core v0.4.1` (2025-08-20), `blox-seo v0.3.1` (2025-08-20), `blox-plugin-netlify v1.2.0` (2025-12-01) | `proxy.golang.org/.../@latest` |
| The upstream starter's `permalinks:` block would rewrite `/authors/`→`/author/`, `/tags/`→`/tag/` | `HugoBlox/theme-research-group/config/_default/hugo.yaml` |
