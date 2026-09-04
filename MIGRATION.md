# MIGRATION — Trypanosomatics Lab site → HugoBlox Kit (Tailwind)

**Runbook. This is the document being executed.**

- `ANALYSIS.md` — why we are going to HugoBlox Kit. Still current.
- `PLAN.md` — **superseded on the target choice.** It plans a move to
  `blox-bootstrap v5` (option B). We chose **option D**. Its §1 inventory,
  §4 baseline method, and §7 content-mapping tables remain valid and are reused
  here; its §2 recommendation and §5–§6 phases are not.

---

## 1. Decision record

| | |
|---|---|
| **Target** | `github.com/HugoBlox/kit/modules/blox` (Tailwind), via the `academic-cv` template as scaffold |
| **Hugo** | 0.162+ extended (latest verified: 0.165.0) |
| **Toolchain** | Go modules, Node ≥20, pnpm, Pagefind. No git submodule. |
| **Repo strategy** | **Branch in this repo.** Not a fresh clone. |
| **Accepted cost** | Visual redesign; section renames with redirects |
| **Decided** | 2026-09-04 |

### Why branch, not fresh clone

156 of 223 commits touch `content/`, from **12 contributors** — lab members who
committed their own profiles. History is incremental (6 commits on a typical
author file), not a bulk import. Netlify site ID, DNS, build hooks, Forms
submissions, and the README badge are all bound to this repo. A better repo name
is available via GitHub rename, which preserves history and sets up redirects.

Prior art in this repo, both cautionary:
- `origin/migrate-wowchemy` — a migration attempt abandoned Aug 2023, now 21
  commits behind master.
- `origin/main` — 400 commits ahead / 157 behind, polluted by a merge of the
  upstream starter's history. Not the deployed branch.

Both should be deleted once this migration lands.

---

## 2. Rules that protect history

1. **Never combine a move with an edit.** Git infers renames by ~50% content
   similarity. `git mv` in a commit of its own; rewrite front matter in the next
   commit. Verify with `git log --follow <new-path>` before continuing.
2. **Merge, don't squash.** A squash-merge recombines the rename commit with the
   edits and reintroduces the problem rule 1 avoids.
3. **Do not import the kit template's git history.** Copy its files in as one
   scaffold commit. `origin/main` is what the alternative looks like.
4. **Tag before merging:** `git tag academic-v4-final`.

---

## 3. What is actually stack-neutral — verified, not assumed

Work that can land on `master` while the old stack still deploys:

| Change | Neutral? | Evidence |
|---|---|---|
| Fix 7 malformed author lists | ✅ | Pure YAML syntax fix |
| TOML → YAML front matter | ✅ | Hugo has parsed both since long before 0.69 |
| **Add** `title` / `first_name` / `last_name` to author profiles | ✅ | v4 reads `.Params.name`; extra keys are inert |
| **Remove** `name:` from author profiles | ❌ | `themes/academic/layouts/partials/widgets/people.html:53` uses `.Params.name` with **no** `.Title` fallback — the People widget would go blank |
| `publication_types` numeric → CSL string | ❌ | `themes/academic/layouts/publication/single.html:24` does `index $pub_types (int .)` — casting `"article-journal"` to int fails |

> An earlier draft of this advice listed `publication_types` and the `name:`
> rename as stack-neutral. Both were checked against the v4 templates and are
> not. They are deferred to Phase 2.

---

## 4. Baseline (captured 2026-09-04)

Built from `master` with the pinned `hugo_extended_0.69.2`:

```
Pages 478 · Paginator 25 · Non-page files 88 · Static 20 · Images 144 · Aliases 78
```

Artefacts in the session scratchpad:

| File | Contents |
|---|---|
| `baseline-urls.txt` | **256** URLs from `sitemap.xml` — the URL contract |
| `baseline-authorlinks.txt` | **262** distinct `/authors/...` link targets with counts |
| `baseline-pages.txt` | **359** rendered HTML page paths |

These are the parity gates for §7. Regenerate them into the repo (or a durable
location) before Phase 2 begins — a session scratchpad is not durable storage.

---

## 5. Phases

### Phase 1 — Stack-neutral content normalisation · branch `content/normalise-front-matter`
Merges to `master` and deploys on the **old** stack. Small, reviewable, low risk.

1. ✅ Fix the 7 malformed author lists.
2. ✅ Normalise `ramiro/_index.md` to LF; add `.gitattributes`.
3. ✅ Add `title` / `first_name` / `last_name` to the 20 author profiles (keep `name`).
4. ⏭️ **TOML → YAML front matter — deferred to Phase 2.** See §5.1.

**Gate:** `hugo692 --gc` builds clean; URL / author-link / page-count parity vs §4.

#### 5.1 Why TOML → YAML was deferred

Mechanical conversion parses the front matter and re-emits it, which **destroys
every explanatory comment** — `# Display name`, `# Organizations/Affiliations`,
`# Set this to [] if you are not using People widget`, and so on. Those comments
are the only documentation the ~12 people who edit these files have.

The cost is real and the benefit is cosmetic: Hugo has parsed both formats since
long before 0.69. In Phase 2 the author and publication files are rewritten
anyway, so the conversion should happen **there**, modelled on the kit template's
own commented YAML archetypes rather than transliterated from TOML.

### Phase 2 — Framework migration · branch `migrate/hugoblox-kit`
Long-lived. Everything below is on this branch only.

1. **Teardown** — remove the `themes/academic` submodule, `.gitmodules`,
   `update_academic.sh`, `page_author.html.patch`, `config/_default/*.toml`,
   `data/themes/`, `data/fonts/`, `assets/scss/`, `layouts/`.
2. **Scaffold** — import the `HugoBlox/theme-academic-cv` template files
   (`go.mod`, `package.json`, `config/_default/*.yaml`, `netlify.toml`,
   `.github/workflows`) as **one** commit. No upstream history.
3. **Move content** — `git mv` **only**, nothing else in the commit:
   - `content/post/` → `content/blog/`
   - `content/talk/` → `content/events/`
   - `content/publication/` → `content/publications/`
   - `content/project/` → `content/projects/`
   - `content/authors/` unchanged
   Verify `git log --follow` on one file per section.
4. **Content rewrite** — `publication_types` → CSL strings (31 files); drop
   `name:` from author profiles; port `image`/`links`/`social` shapes;
   **strip the `@` from every author handle** (see §5.2).

#### 5.2 The `@handle` convention breaks on modern Hugo — must-fix

Content references lab members as `authors: ["@emir", "Morten Nielsen"]`.
On Hugo 0.69.2 the `@` is stripped when the taxonomy term is urlized, so
`@emir` resolves to the profile at `content/authors/emir/`. **Modern Hugo no
longer strips it.** Verified with a minimal site on 0.165.0:

```
out165/authors/@emir/index.html     <- new, empty term page
out165/authors/emir/index.html      <- the profile, now unlinked
```

The current build produces **zero** URLs containing `@`; on 0.165 every handle
would generate a dead term page and the publication → author-profile links —
the single most important feature of this site — would silently break.

Scope: **121 occurrences across 49 files**, 12 distinct handles:
`@aleacker @alejandro @emir @fernan @leonardo @leonel @lionel @mercedes @paula
@ramiro @raul @santiago`.

Fix: strip the `@` prefix throughout during the Phase 2 content rewrite, then
verify against `baseline-authorlinks.txt` (262 targets). Do **not** attempt this
in Phase 1 — `anchorize` on 0.69.2 maps `@emir` and `emir` to the same term, so
it is safe either way on the old stack, but it belongs with the rest of the
content rewrite.
5. **Landing page** — `content/home/*.md` → `content/_index.md` with
   `sections:`, preserving the 11 sections and their anchor IDs.
6. **Blocks** — map widgets to Tailwind blocks; write the missing `tag-cloud`
   block (~half a day).
7. **Redirects** — `static/_redirects` for every moved URL. **Mandatory.**
8. **Overrides** — re-apply Altmetric/Dimensions badges to the Tailwind
   citation/compact/card views; delete the `page_author` hack (native upstream).
9. **Design** — theme tokens to approximate the `tryps` palette; decide dark mode.

**Gate:** §7 in full, on a Netlify deploy preview.

### Phase 3 — Cutover
Tag `academic-v4-final`, merge (**not** squash), watch production, spot-check 10
baseline URLs live, delete `origin/main` and `origin/migrate-wowchemy`, rewrite
`README.md`, rename the GitHub repo.

---

## 6. URL contract

Section renames move public URLs. Every one may be cited in a paper.

| Old | New | Redirect |
|---|---|---|
| `/post/...` | `/blog/...` | `/post/* /blog/:splat 301` |
| `/talk/...` | `/events/...` | `/talk/* /events/:splat 301` |
| `/publication/...` | `/publications/...` | `/publication/* /publications/:splat 301` |
| `/project/...` | `/projects/...` | `/project/* /projects/:splat 301` |
| `/publication_types/2/` | `/publication_types/article-journal/` | per-type 301 |
| `/authors/...`, `/tags/...`, `/categories/...` | unchanged | — |

Do **not** adopt the upstream `permalinks:` block, which would rewrite
`/authors/` → `/author/` and `/tags/` → `/tag/`.

---

## 7. Verification gates

- [ ] Build clean, zero errors, no new warnings
- [ ] Every one of the 256 baseline URLs resolves — directly or via 301
- [ ] Author cross-links match `baseline-authorlinks.txt` (262 targets)
- [ ] Each publication shows the same set of author profile cards
- [ ] People section: same groups, same order, same members
- [ ] Altmetric + Dimensions badges render on single **and** list views
- [ ] Search returns results (Pagefind)
- [ ] Contact form submits to Netlify Forms
- [ ] RSS validates; `sitemap.xml` present
- [ ] No `cdn.jsdelivr.net` / `unpkg.com` references (the CDN cleanup is a goal of D)
- [ ] Deploy preview green before merge

---

## 8. Open questions — resolved 2026-09-04

| # | Question | Decision |
|---|---|---|
| 1 | Dark mode | Use the `tryps` palette. `data/themes/tryps.yaml`. See §8.1. |
| 2 | Hero image | `static/img/headers/bubbles-wide-tryp-binary.jpg`, copied to `assets/media/`. |
| 3 | Analytics | Keep `UA-1674362-6`. See §8.3 — **not** a GA4 id. |
| 4 | Superuser | `fernan`. `trypanosomatics` keeps a profile but is no longer owner. |
| 5 | Inactive widgets | Parked in `archive/home-widgets/`. See §8.5. |
| 6 | Map | MapLibre/OpenFreeMap active; Google embed documented alongside. |
| 7 | Repo name | `trypanosomatics-website`. See §8.7 for the Netlify procedure. |

### 8.1 Dark mode — proposed palette

The old theme was light-only (`light = true`), so there was no dark variant to
port; these values are new and are the part worth reviewing.

| Role | Light (unchanged) | Dark (proposed) |
|---|---|---|
| primary | `#69870E` | `#CFF462` |
| secondary | `#54914D` | `#7DA211` |
| background | `#ffffff` | `#0b1f24` |
| foreground | `#1b2a2e` | `#e9f1e4` |
| header bg / fg | `#7DA211` / `#024452` | `#04333c` / `#CFF462` |

Reasoning: `#69870E` is a dark olive and fails contrast on a dark ground, so
primary lifts to `#CFF462` — a colour the palette already contains (it was the
alert background in the old `custom.scss`) rather than an invented one. The dark
background derives from the palette's own `#024452` teal instead of a neutral
grey, so both modes read as the same brand.

### 8.3 Analytics is Universal Analytics, not GA4

Checked against the live site: `trypanosomatics.org` serves

```html
<script async src="https://www.googletagmanager.com/gtag/js?id=UA-1674362-6">
```

There is **no `G-` measurement id** in the served HTML, and none in the repo.
The migrated config reproduces this exactly, so whatever GA4 property is
currently receiving this traffic keeps receiving it — Google can forward a UA
`gtag.js` tag into a GA4 property through a connected site tag.

That bridge is a legacy mechanism. The durable fix is to read the real `G-…`
measurement id off the GA4 property (Admin → Data Streams → the web stream) and
put it in `hugoblox.analytics.google.measurement_id`. Until then this is
carried-over behaviour, not a working GA4 install.

### 8.5 The parked widgets are old, not new

`archive/home-widgets/` holds the **Academic v4** widgets that were already
`active = false` before the migration: `demo` (blank), `skills` (featurette),
`experience`, `accomplishments`. They are history, not new features.

The new things worth trying are Hugo Blox blocks this site does not yet use:
`resume-experience`, `resume-skills`, `resume-awards` (the direct counterparts
of those four), plus `stats`, `testimonials`, `faq`, `gallery`, `steps`,
`focus-areas`, `logos`, `tech-stack`, `cta-card`.

### 8.7 Renaming the repository and Netlify

Renaming `academic-kickstart` → `trypanosomatics-website` is safe, but relink
Netlify rather than relying on the redirect.

- GitHub redirects the old path, and Netlify builds generally keep working
  through it — but the documented failure mode is builds failing at
  *"preparing repo"*, and Netlify's UI keeps showing the old name either way.
#### What "relinking" means

Netlify stores two things about the repo: its path (`trypanosomatics/academic-kickstart`)
and a GitHub webhook that fires on push. Renaming the repo makes the stored path
stale. Relinking just refreshes it. It points the **existing** site at the new
path — it does **not** create a new site — so all of this is preserved:

- the site ID and the `*.netlify.app` subdomain
- the `trypanosomatics.org` custom domain and its DNS records
- environment variables and build settings
- Netlify Forms submissions already collected
- the full deploy history, including rollback targets

#### Steps

1. Land this migration on `master` and confirm a **green production build**.
   Do not rename before this; it adds a variable to an already large change.
2. GitHub → the repo → **Settings** → rename to `trypanosomatics-website`.
3. Netlify → the site → **Project configuration → Build & deploy → Continuous
   deployment → Repository → Manage repository → Link to a different repository**.
4. Choose `trypanosomatics/trypanosomatics-website`. Keep branch `master`,
   build command `hugo`, publish directory `public`.
5. Push a trivial commit and confirm a deploy starts. This is the real test —
   it proves the **webhook** fires, not merely that GitHub's redirect works.
6. Update the Netlify badge URL at the top of `README.md` and
   `hugoblox.repository.url` in `config/_default/params.yaml`.

If step 5 produces nothing, the webhook did not transfer: unlink and relink
once more, or add the webhook by hand from the GitHub repo's
**Settings → Webhooks**.

Sources: [Netlify docs — repo permissions and linking](https://docs.netlify.com/build/git-workflows/repo-permissions-linking/),
[Netlify forum — renaming a git repository](https://answers.netlify.com/t/renaming-a-git-repository/37168)

## 9. Progress log

| Date | Phase | Status |
|---|---|---|
| 2026-09-04 | Baseline | ✅ 256 URLs / 262 author links / 359 pages captured |
| 2026-09-04 | Phase 1 | ✅ complete on `content/normalise-front-matter` — 4 commits, all gates green |
| 2026-09-04 | Phase 4 | 🚧 fonts and palette. Two upstream font bugs fixed (§8.8); theme picker disabled. |
| 2026-09-04 | Phase 2 | 🚧 open questions 1-6 resolved; **builds on Hugo 0.165.0** — 466 pages, no errors; 256/256 baseline URLs resolve. Remaining work in §5.5. |

#### 5.3 Hugo Blox needs `tailwindcss` on `security.exec.allow`

An unmodified Kit template does **not** build on Hugo 0.165. Hugo's built-in
`security.exec.allow` is `sass`/`go`/`git`/`node`/`postcss`; the blox module's
Tailwind v4 pipeline shells out to `tailwindcss` and its config comments assume
the defaults already permit it. They do for the Node *permission* sandbox
(`allowChildProcess`), but not for `exec`. Added to `config/_default/hugo.yaml`.

#### 5.4 Blocks: what mapped, what had to be written

| v4 widget | Kit block |
|---|---|
| `about` | `resume-biography` |
| `pages`, `featured` | `collection` (`view: card` / `article-grid` / `citation`) |
| `portfolio` | `portfolio` |
| `people` | `team-showcase` |
| `contact` | `contact-info` |
| `hero` | `hero` |
| `slider` | `logos` — Kit has no carousel; `logos` carries the same name/image/url/description per item |
| `tag_cloud` | **written for this site** — `hugo-blox/blox/all-access/tag-cloud/` |

#### 5.5 Phase 2 remaining

1. **Altmetric + Dimensions badges** — not yet reinstated. The v4 overrides read
   `$item.Params.doi`; Kit deprecates top-level `doi` in favour of
   `hugoblox.ids.doi`, so do the front-matter move first, then write the
   override against `_partials/views/citation.html` and `single.html`.
2. ~~The flat `publication` string~~ — **done 2026-09-04.** All 32 migrated to
   `publication: {name, short_name, volume, issue, pages, publisher}`; the build
   is now warning-free (was 79 warnings at the start of Phase 2). Details in §8.9.

3. **Design → Phase 4.** The `tryps` palette and dark mode are done; fonts
   (Play / Open Sans / PT Mono) and overall styling are not. Kit font packs live
   in the module's `data/fonts/`; a `tryps` pack would be authored the same way
   as the theme pack.
4. **External co-authors are no longer hyperlinked.** Kit links an author only
   when it can resolve profile data, so lab members link to their profiles and
   external co-authors render as plain text. Their taxonomy pages still exist
   and are still in the sitemap; nothing links to them. Arguably an improvement
   — needs a decision, not a silent change.
5. **README** — still describes the pinned 0.69.2 workflow.
6. **`hugo mod get ./...` drifts.** It upgraded the netlify integration and
   pulled `HugoBlox/kit v4.8.0+incompatible`. Pin exact versions before merge.

### Findings from Phase 1

**The People widget has no sort at all.** `themes/academic/layouts/partials/widgets/people.html:24`
is a bare `where` with no `sort`, so members within a group come back in Hugo's
default page order. Every lab member currently carries `weight = 10`, so the
ordering has always been decided by an arbitrary tie-break. Adding `title`
changed that tie-break and swapped two Alumni (`sebastian` ↔ `ssneider`) and two
entries in the authors index (`mercedes` ↔ `paula`).

*Action for Phase 2:* set an explicit `sort_by` on the `team-showcase` block, and
give members distinct weights within each group. **Who is listed first inside a
group is a decision for the lab, not a default to be invented.**

**`enableGitInfo` makes rendered output depend on the working tree.** Editing a
file changes its `article:modified_time` and JSON-LD `dateModified`, and shifts
the date-based tie-break in the related-content lists. Byte-comparisons against a
baseline must expect this. It settles once changes are committed, since Netlify
builds from git history.

---

## 8.8 Why the fonts and navbar colour did not render

Both reported symptoms had causes in different places, and neither was the
palette itself — `:root` carried `--hb-color-header-bg: #7DA211` and
`--hb-font-heading: 'Play'` correctly the whole time.

### Fonts: two bugs in one Google Fonts request

The page requested every family in a single stylesheet URL, and it was invalid,
so **no** font loaded and everything fell back to system sans.

1. **Comma vs semicolon.** `typography.html` joined discrete weights with `,`
   (`Play:wght@400,700`). The CSS2 API requires `;`. Response: HTTP 400.
   Fixed by overriding the partial — see `OVERRIDES.md`.
2. **Wrong variable range.** Upstream hardcodes `100..900` for any family
   marked `variable: true`. Open Sans's `wght` axis is `300..800`, so Google
   dropped it even after fix 1. Fixed by declaring Open Sans static with
   explicit weights in `data/fonts/tryps.yaml`.

Both fail silently: one bad request, no console error beyond a failed
stylesheet, and a page that looks merely "unstyled". `OVERRIDES.md`
carries a two-line regression test.

### Navbar: the theme picker

`hugoblox.header.theme_picker` was on (template default). It ships **all twelve**
theme packs' CSS into every page — ~95 KB — and, once a visitor uses the
dropdown, writes `localStorage['hb-theme-pack']` and stamps `data-theme-pack`
on `<html>`. Those rules come after `:root`, so they override the site's own
colours **for that visitor only**, until the key is cleared. The white navbar
was the `default` pack's `#f1f5f9` winning that way.

Now disabled: the packs are gone from the page (95 KB → 6 KB) and nothing can
override `:root`. The light/dark toggle is separate and still on.

> **If the navbar still looks wrong in a browser used before this change**, that
> browser still has the stale key. Clear it once:
> DevTools → Application → Local Storage → delete `hb-theme-pack`, then hard
> reload. Or from the console: `localStorage.removeItem('hb-theme-pack')`.

---

## 8.9 Publication front matter migration

All 32 publications moved from the flat string to the structured shape. 31 were
parsed mechanically against five recognised patterns; two needed hand treatment.

**What the display gains and loses.** `resolve_publication` renders
`*Name*, volume(issue), pages`, so:

- The DOI URL that used to be pasted into the string is gone from the citation
  text. Nothing is lost — all 32 carry `hugoblox.ids.doi`, which already renders
  a proper DOI link and drives the Altmetric/Dimensions badges. Checked before
  migrating: no publication had its only DOI inside the string.
- `_pp. 304--12_` becomes `304–12`. The `pp.` label and markdown emphasis are
  now supplied by the template, and the `--` was a BibTeX artifact that rendered
  literally.
- `publication_short` is removed; its value becomes `publication.short_name`,
  dropped where it merely repeated the full name.

**Hand-mapped cases.**

| Page | Why | Treatment |
|---|---|---|
| `2012-Shanmugam` | A book chapter, not a journal article: *Chapter 3, pp. 43-59, In 'Parasitic Helminths…', Edited by Conor R Caffrey, Wiley, Weinheim, Germany* | `name` = the book, `pages` = 43–59, and the chapter number and editor ride in `publisher`, which the template appends after the citation. The schema has no field for either. |
| `2021-Ricci-aprank-biorxiv` | `publication_short` was `2021.04.27.441630` — the preprint id, not a journal abbreviation. As `short_name` it would have rendered *\*2021.04.27.441630\** in list views. | Dropped; falls back to `bioRxiv`. |
| `2019b-SalasSarduy` | `publication_short` was `Curr Med Chem 26 (36)`, with volume and issue baked into the abbreviation, so the citation rendered them twice: *Curr Med Chem 26 (36), 26(36)*. | Corrected to `Curr Med Chem`. |

**TOML note.** Structured values are written as dotted keys
(`publication.name = "…"`), never a `[publication]` table header — a header
absorbs every following top-level key into the table. This bit the earlier
`doi` migration and corrupted four files before it was caught.

**Verification.** Front matter re-parsed for all 32 (title, authors, date, DOI
all intact, `publication` a map, no `publication_short` left); build clean with
**0 warnings and 0 errors**; every rendered citation string read back and
eyeballed.

---

## 8.10 Navbar anchors broke on every page except the home page

From a subpage, clicking a nav item appended the fragment to the current URL —
`/publications/foo/` + *Talks* gave `/publications/foo/#talks` instead of going
home and scrolling.

Cause: the menu used bare fragments (`#talks`), which resolve against the
current document. Hugo Blox's `navbar.html` tries to handle exactly this, but
the fix is broken (blox `v0.0.0-20260527025321`):

```gotemplate
{{- if findRE `^#` .URL -}}
  {{- if not $.IsHome -}}
    {{- $url = site.Home.RelPermalink -}}   {{/* computes the "/" prefix … */}}
  {{- end }}
  {{- $url = .URL -}}                        {{/* … then discards it, always */}}
```

The second assignment sits outside the `if`, so the prefix is overwritten on
every page. The same shape appears in the dropdown branch a few lines above.

Fixed **without an override** by writing the menu URLs as `/#talks` in
`config/_default/menus.yaml`. A leading slash means `findRE "^#"` no longer
matches, so the URL takes the normal `relLangURL` path and is emitted verbatim.
That avoids copying a 220-line template to change two lines.

Verified: every header anchor on the home page, a publication page and an author
page is `/#…`, no bare `#…` href remains anywhere, and all nine target ids exist
on the landing page.
