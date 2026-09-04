# ANALYSIS — Modernising `HugoBlox/theme-research-group`

**Question asked:** is `HugoBlox/theme-research-group` the current HugoBlox offering,
and what changes or migrations are worth doing to bring it up to date with the
better-maintained HugoBlox themes — current Hugo, current CSS/HTML/JS?

**Short answer:** No, it is not current. It has been frozen since October 2024,
its framework dependency was **archived and formally deprecated in January 2026**,
and the Research Group template has been **discontinued with no successor** in the
modern HugoBlox line-up. It nevertheless still builds cleanly on Hugo 0.165.0 —
I verified this by building it — so this is a planning problem, not an emergency.

**Companion document:** `PLAN.md` (migrating *this site* off Academic v4).
§8 of this file corrects one claim in that plan.

---

## 1. Method

Everything below was verified in September 2026 against live sources, not recalled:

- GitHub REST API for repository status, commit history, tags, and directory trees.
- The Go module proxy for module versions and availability.
- The `hugoblox.com/templates/` gallery for what is actually on offer.
- **A live build**: I downloaded Hugo `v0.165.0+extended`, cloned
  `HugoBlox/theme-research-group@main`, resolved its modules, and built it. All
  build results in §4 are observed output, not inference.

---

## 2. Is research-group current? No.

| Signal | Finding |
|---|---|
| Last commit | `b59e85b2`, **2024-10-12** — "starters: upgrade to support Hugo breaking changes" (~23 months ago) |
| Repo status | Not archived, still marked `is_template`, 403 stars / 405 forks |
| README | Still Wowchemy-branded: "no-code, widget-based **Wowchemy** page builder", links to `docs.hugoblox.com`, `@wowchemy` Twitter |
| Framework dep | `blox-bootstrap/v5 v5.9.8-0.20241012174104-661cadc17327` |
| Listed on hugoblox.com/templates? | **No** |

### 2.1 The dependency is formally dead

`blox-bootstrap` no longer exists in `HugoBlox/kit@main`. It was moved to
`HugoBlox/wowchemy-bootstrap-legacy`, which is **archived** (last push 2026-01-05).
That repo's own README is unambiguous:

> **This repository is legacy and is no longer maintained.** It exists for
> historical reference only (the old Bootstrap-based framework from the Wowchemy era).
> …
> **Status:** Archived / deprecated · **Support:** None (issues and PRs are not monitored)
> - No new features · No bug fixes · **No security updates**

Its description reads: *"DEPRECATED — replaced by HugoBlox/kit"*.

The research-group **starter itself** was also moved into that archived repo
(`wowchemy-bootstrap-legacy/starters/research-group`), alongside `academic-cv`,
`course`, `portfolio`, `second-brain`, and `markdown-slides`.

### 2.2 What replaced it

`HugoBlox/kit` (formerly `hugo-blox-builder`) is the active monorepo: 9,668 stars,
last push **2026-08-04**, modules `blox` (Tailwind), `analytics`, `integrations`,
`slides`. Templates in `kit/templates` and on the public gallery:

`academic-cv` · `data-science-blog` · `dev-portfolio` · `documentation` ·
`link-in-bio` · `markdown-slides` · `resume` · `saas-landing-page` · `starter`

Nine templates. **None is a research group, lab, team, or organization site.**

### 2.3 The strategic finding

> The Bootstrap-era template family (research-group, course, second-brain,
> portfolio) was **retired, not ported**. The Tailwind line-up is oriented toward
> *individual* sites — CV, resume, portfolio, link-in-bio — plus docs and SaaS
> marketing. The closest academic template, `academic-cv`, ships
> `content/authors/_index.md` with `build.render: never`: a **single-author** site
> by default.

Anyone maintaining a *group* site on HugoBlox is now, in effect, self-supporting.
That is the central fact any modernisation decision has to be built around.

---

## 3. Technology gap

### 3.1 Client-side stack

| Layer | research-group (blox-bootstrap v5.9.7/.8) | kit `blox` (Tailwind, v0.12.0) |
|---|---|---|
| CSS framework | **Bootstrap 4.6.1** — EOL, jQuery-dependent | **Tailwind CSS v4** (`@import "tailwindcss"`), `@tailwindcss/typography` |
| DOM library | **jQuery** (bundled, required by Bootstrap 4, Fancybox, mark.js) | **Alpine.js 3.15** + **Preact 10.27**; no jQuery |
| Math | MathJax 3 (CDN) | **KaTeX 0.16.22** (bundled) |
| Diagrams | **mermaid 9.1.3** (2022) | **mermaid 11.12** |
| Plots | **plotly.js 1.55.2** (2020) | **plotly.js 3.1** |
| Search | Fuse.js **3.2.1** (2018) + jQuery mark.js, or Algolia | **Pagefind 1.4** (static index) |
| Maps | Google Maps (**API key required**) or `gmaps.js 0.4.25` / Leaflet 1.7.1 | **MapLibre GL 4.7 + OpenFreeMap** — no key, no tracking |
| Lightbox | Fancybox 3.5.7 (jQuery, non-commercial licence caveat) | medium-zoom; `gallery` block with lightbox |
| Portfolio filter | Isotope 3.0.6 + imagesLoaded | Alpine.js transitions |
| Cookie banner | Osano cookieconsent 3.1.1 (unmaintained since 2020) | n/a (fewer third-party calls to consent to) |
| Icons | Font Awesome (bundled) + academicons 1.9.4 (CDN) | bundled |
| Delivery | **jsDelivr CDN** for most optional libs | **Vendored locally**, built with **Vite 7** |
| Build tooling | Hugo Pipes only | pnpm 10.14, Node ≥20, Vite 7, Biome, Pagefind |

### 3.2 Measured output (my build of research-group)

- `wowchemy.css` **182 KB** + `vendor-bundle.min.css` **102 KB** = **285 KB of CSS**
- `vendor-bundle.min.js` **176 KB** (jQuery + Bootstrap 4 bundle + instant.page)
- **62 references to `cdn.jsdelivr.net`** and 1 to `unpkg.com` across the built pages

That last line is the most consequential item in this table. Every visitor's
browser contacts a third-party CDN. For a lab site in the EU or handling EU
visitors this is a live GDPR question — the same class of issue that produced the
German Google Fonts rulings. The Tailwind stack vendors everything locally and
eliminates it.

### 3.3 Content model

Both lines share the essentials — `authors` taxonomy, `publication_types` as CSL
strings, page bundles, `featured.*` images, `user_groups`. Differences:

| | Bootstrap | Tailwind |
|---|---|---|
| Sections | `post`, `publication`, `event`, `project`, `people` | `blog`, `publications`, `events`, `projects` |
| Page builder | `content/_index.md` with `sections:` (v2) or `content/home/*.md` (v1 shim) | `content/_index.md` with `sections:` only |
| Publication metadata | title, authors, `publication`, `publication_short`, `doi` | adds structured `publication: {name, volume, issue}`, `peer_reviewed`, `open_access`, `license`, `awards[]`, `funding[]`, `cite.bib` |
| Author pages | rendered by default | `build.render: never` by default; opt-in |
| Appearance config | `data/themes/*.toml` (`[light]`/`[dark]`) | CSS custom properties / Tailwind theme |

Publication metadata is the one place where the modern line is materially *richer*
than what research-group offers today.

---

## 4. Compatibility with current Hugo — measured

**Latest Hugo: `v0.165.0` (2026-08-12). Last version research-group was verified
against: `0.135.0` (Oct 2024). A ~30-release gap.**

### 4.1 It builds

```
$ hugo --gc            # Hugo v0.165.0+extended, theme-research-group@main
Pages 48 · Non-page files 11 · Static files 9 · Processed images 39 · Aliases 9
Total in 11276 ms
```

Verified correct in the output: landing page with all 5 blocks
(`section-hero`, 2× `section-collection`, 2× `section-markdown`), the `cta`
shortcode, `/publication/` with citation views, `/people/` with person cards,
`sitemap.xml`, and `index.json` (the search index).

**The starter is functional on the newest Hugo today.** That is the good news, and
it means nothing here is urgent.

### 4.2 Four deprecation warnings

| Warning | Deprecated in | Where | Fix |
|---|---|---|---|
| `languages.en.languageCode` → use `locale` | 0.158.0 | starter `hugo.yaml` | one-line config change |
| `.Site.LanguageCode` → `.Site.Language.Locale` | 0.158.0 | module `_default/baseof.html:4`, `_default/rss.xml:19` | module patch |
| `.Site.Data` → `hugo.Data` | 0.156.0 | module | module patch |
| `.Site.AllPages` | 0.156.0 | module | module patch |

Hugo's policy is warn → error → removal. Three of the four are inside the
**archived** module, so nobody upstream will fix them.

### 4.3 One API is already removed — a latent build breaker

`blox-bootstrap/layouts/partials/page_edit.html:11` calls `site.IsMultiLingual`,
which **no longer exists** in Hugo 0.165. Confirmed directly:

```
error calling partial ... page_edit.html:11:25:
  can't evaluate field IsMultiLingual in type interface {}
```

The default build survives only because the call sits in a branch that is not
reached. Reproduced by satisfying all three conditions:

1. `features.repository.url` set, **and**
2. `features.repository.content_dir` empty, **and**
3. a page with `editable: true`

```
ERROR error building site: ... page_footer.html at <partial "page_edit" .>:
  page_edit.html:11:25: can't evaluate field IsMultiLingual in type interface {}
```

> **The starter builds on the latest Hugo only because one broken template happens
> not to be reached.** Turning on "Edit this page" — an advertised feature —
> fails the build, and the fix must be applied downstream because upstream is archived.

### 4.4 A silently dropped template

```
WARN skipping template file ".../blox-seo@v0.2.3/layouts/_default/_markup/sitemap.xml":
     unrecognized render hook template
```

Hugo 0.146 restructured template lookup (`layouts/shortcodes/` → `layouts/_shortcodes/`,
stricter `_markup/` handling). The `blox-seo` module's custom sitemap no longer
loads; Hugo's built-in sitemap is emitted instead. The site still has a sitemap,
but whatever SEO customisation that template carried is gone, silently. Expect
more of this class of breakage with each Hugo release.

### 4.5 Dependency drift on `hugo mod get`

`hugo mod get ./...` silently upgraded two plugins past what the starter pins
(`blox-plugin-decap-cms` → v0.2.0, `blox-plugin-netlify` → v1.2.0) and pulled in
`hugo-blox-builder v4.8.0+incompatible`. The starter's `go.mod` says `go 1.15`.
Any fork should pin exact versions and commit `go.sum`.

### 4.6 Module availability

All modules resolve through the Go proxy despite the repo rename and archival:
`blox-bootstrap/v5 v5.9.7`, `blox-core v0.3.1`/`v0.4.1`, `blox-seo v0.2.3`/`v0.3.1`,
`blox-plugin-netlify v1.2.0`. The proxy is immutable, so **availability is durable
even though maintenance is not.** Vendoring (`hugo mod vendor`) removes even that
dependency.

---

## 5. Options

| | Effort | Risk | Modernises CSS/JS? |
|---|---|---|---|
| **A. Do nothing, pin** | ~0 | Grows every Hugo release | No |
| **B. Fork + compatibility patches** | 1–2 days | Low | No |
| **C. Fork + modernise the Bootstrap stack in place** | 3–6 weeks | High | Partly |
| **D. Rebuild on `kit`/`blox` (Tailwind)** | 1–3 weeks | Medium | Fully |

### A. Do nothing, pin Hugo

Pin `0.165.0` (or `0.135.0`) and stop. Legitimate for a site nearing end of life.
Cost: the four deprecations become errors on Hugo's own schedule, and no security
fixes are coming for jQuery/Bootstrap 4/Fancybox/Fuse 3.

### B. Fork + compatibility patches — **the floor**

Fork `blox-bootstrap` into `layouts/` overrides (or a maintained module fork) and
fix the five verified issues:

1. `page_edit.html:11` — replace `site.IsMultiLingual` with
   `(gt (len site.Languages) 1)`. **Fixes a real build breaker.**
2. `baseof.html:4`, `rss.xml:19` — `site.LanguageCode` → `site.Language.Locale`.
3. `.Site.Data` → `hugo.Data`; `.Site.AllPages` → `site.Pages`/`.Site.RegularPages`.
4. `hugo.yaml` — `languages.en.languageCode` → `locale`.
5. Re-home the `blox-seo` sitemap template, or drop it and accept Hugo's default.

Then pin exact module versions, commit `go.sum`, and optionally `hugo mod vendor`.

Result: builds warning-free on current Hugo, no Hugo-side time bomb. **Does not**
address Bootstrap 4, jQuery, or the 62 CDN calls. ~1–2 days.

### C. Fork + modernise the Bootstrap stack in place

Bootstrap 4→5 (drops jQuery, but renames most utility classes and rewrites every
component's markup), Fancybox→GLightbox, Fuse 3→7, mermaid 9→11, plotly 1→3,
Google Maps→MapLibre, self-host every CDN asset.

**Not recommended.** This is a full rewrite of ~200 templates and all the SCSS, to
land on a design system whose upstream is archived. The effort is comparable to
option D and the destination is strictly worse.

### D. Rebuild on `kit`/`blox` (Tailwind) — **the destination**

Adopt the maintained framework. What transfers, what has to be built:

**Transfers directly** — the academic machinery is all present in `blox`:
`layouts/_partials/page_author.html`, `page_author_card.html`,
`page_metadata_authors.html`, `views/` (card · citation · compact · list ·
masonry · showcase), `authors/`, `taxonomy.html`, `terms.html`. The
`content-collection` block filters by *folders, tags, categories, **authors**,
publication types* and renders a **citation** view. Multi-author cross-linking to
author profile pages — the thing this site most depends on — is a first-class
feature, not something to rebuild.

**`team-showcase` is a direct successor to the `people` block**, and a better one.
From its README: user groups, per-group sort overrides, sort by last name /
graduation year / weight / any author field, avatar, role, organizations,
interests, social links, responsive grid, optional recruitment CTA.

**Genuinely missing:**

| Bootstrap block | Tailwind status |
|---|---|
| `tag_cloud` | **Absent.** Must be written — a small block over `site.Taxonomies.tags`. Half a day. |
| `slider` | **Absent as such.** The `gallery` block gained carousel and slideshow layouts (May 2026) and covers most of the use case. |
| `accomplishments`, `experience`, `skills` | Replaced by `resume-awards`, `resume-experience`, `resume-skills` |
| `about.biography` | Replaced by `resume-biography` / `resume-biography-3` |

**Costs:** section renames (`post`→`blog`, `talk`/`event`→`events`,
`publication`→`publications`) with redirects; Node + pnpm + Pagefind in the build;
Hugo 0.162+; a visual redesign, since Tailwind output will not look like
Bootstrap 4.

---

## 6. Recommendation

**Do B now. Plan D. Never do C.**

1. **Immediately — option B (1–2 days).** Fix the five verified defects,
   especially `site.IsMultiLingual`. Pin exact module versions and commit
   `go.sum`. Consider `hugo mod vendor` so the site cannot be broken by anything
   upstream. This is cheap, purely defensive, and buys years.
2. **Then decide on D deliberately, on design grounds.** There is no forcing
   function — the thing builds on the newest Hugo. Move when the group wants a
   refresh, not under pressure. The one item that could force it earlier is the
   **CDN/GDPR exposure** (§3.2), which option B does not fix.
3. **Never C.** Rewriting for Bootstrap 5 costs as much as D and lands on an
   archived framework.

### If contributing upstream rather than forking

The `site.IsMultiLingual` fix is a two-line PR that would unbreak the "Edit this
page" feature for every remaining Bootstrap-era site. But
`wowchemy-bootstrap-legacy` is **archived — PRs cannot be opened against it.**
The only viable upstream contributions are to `HugoBlox/kit`: a `tag-cloud` block,
and a **research-group / lab template** to fill the gap left when the Bootstrap
one was retired. Given `kit`'s activity (25 open issues, frequent commits), a
well-built team-site template is plausibly welcome. That is a community
contribution, not a prerequisite for this site.

---

## 7. Concrete work items — option B

| # | File | Change | Why |
|---|---|---|---|
| 1 | `layouts/partials/page_edit.html:11` | `site.IsMultiLingual` → `(gt (len site.Languages) 1)` | **Removed API; breaks the build when reached** |
| 2 | `layouts/_default/baseof.html:4` | `site.LanguageCode` → `site.Language.Locale` | Deprecated 0.158 |
| 3 | `layouts/_default/rss.xml:19` | same | Deprecated 0.158 |
| 4 | module templates using `.Site.Data` | → `hugo.Data` | Deprecated 0.156 |
| 5 | module templates using `.Site.AllPages` | → `site.Pages` / `.Site.RegularPages` | Deprecated 0.156 |
| 6 | `config/_default/languages.yaml` | `languageCode:` → `locale:` | Deprecated 0.158 |
| 7 | `go.mod` | pin exact versions; commit `go.sum`; raise `go 1.15` | `hugo mod get` drifts (§4.5) |
| 8 | repo | `hugo mod vendor` | Immunity from upstream churn |
| 9 | `data/assets.toml` | self-host or drop CDN libs | 62 third-party calls (§3.2) |
| 10 | CI | build on current Hugo per PR, fail on new deprecations | Turns future breakage into a red check |

Items 1–6 are mechanical. Item 9 is the one with real user-facing value and is the
natural stopping point before committing to option D.

---

## 8. Correction to `PLAN.md`

`PLAN.md` §2.1 states that the Tailwind `blox` module has *"no `people` … block"*
and treats rebuilding people/tag-cloud/slider/featured as roughly four blocks of work.
**That overstated the gap.** Closer inspection shows:

- `team-showcase` is a full `people` replacement with `user_groups`, per-group
  sorting, avatars, roles, organizations, interests, and social links.
- `content-collection` covers both `pages` and `featured`, including the
  **citation** view and filtering by author and publication type.
- Multi-author cross-linking to profile pages is native (`page_author.html`,
  `page_author_card.html`, `page_metadata_authors.html`).
- The `gallery` block's carousel/slideshow layouts largely cover `slider`.

**Only `tag_cloud` is genuinely absent**, and it is roughly half a day's work.

This does **not** overturn `PLAN.md`'s recommendation — Tailwind still means a
visual redesign, section renames with redirects, and a Node/pnpm/Pagefind build
chain, which is exactly what "same visual appearance" rules out for the immediate
migration. But it makes the eventual move to Tailwind materially cheaper than
`PLAN.md` §11.7 estimates ("3–4× this migration"). **A realistic estimate is
1–2×.** `PLAN.md` §2.1 and §11.7 should be amended accordingly.

---

## Appendix — verified evidence

| Claim | Evidence |
|---|---|
| research-group frozen 2024-10-12 | GitHub API `pushed_at`; last commit `b59e85b2` |
| Its last commit was only a Hugo bump (0.125.7→0.135.0, `paginate`→`pagination.pagerSize`) | Commit diff of `b59e85b2` |
| `blox-bootstrap` archived + deprecated | `HugoBlox/wowchemy-bootstrap-legacy` — `archived: true`, README warning banner, description "DEPRECATED — replaced by HugoBlox/kit" |
| research-group starter moved into the archived repo | `wowchemy-bootstrap-legacy/starters/research-group` |
| No research-group successor | `kit/templates` (9 entries) and `hugoblox.com/templates/` — no team/lab/group template |
| `academic-cv` is single-author by default | `content/authors/_index.md` → `build.render: never` |
| Bootstrap 4.6.1 | `assets/scss/_vendor/bootstrap/bootstrap.scss:2` |
| jQuery bundled and required | `layouts/partials/site_js.html:5` — `slice "jquery.min" "bootstrap.bundle.min" "instantpage"` |
| mermaid 9.1.3, plotly 1.55.2, fuse 3.2.1, fancybox 3.5.7, leaflet 1.7.1, gmaps 0.4.25, cookieconsent 3.1.1 | `data/assets.toml` |
| Tailwind CSS v4 | `kit/modules/blox/assets/css/main.css:13` — `@import "tailwindcss"` |
| Alpine 3.15, KaTeX 0.16.22, mermaid 11.12, plotly 3.1, MapLibre 4.7, Preact 10.27, Vite 7 | `kit/package.json` |
| Pagefind + Tailwind 4 + pnpm 10.14 | `theme-academic-cv/package.json` |
| Latest Hugo v0.165.0 (2026-08-12) | GitHub releases API |
| research-group builds on 0.165.0 | Live build: 48 pages, 39 images, 11.3 s |
| 4 deprecation warnings | Build output |
| `site.IsMultiLingual` removed | `can't evaluate field IsMultiLingual in type interface {}`; absent from `hugolib/site.go` and from the Hugo docs' Site-methods list |
| `page_edit.html` breaks the build when reached | Reproduced by setting `features.repository.url`, clearing `content_dir`, and marking a post `editable: true` |
| `blox-seo` sitemap template silently skipped | Build warning: "unrecognized render hook template" |
| 62 jsDelivr + 1 unpkg reference in built HTML | `grep` over the built `public/` |
| CSS 285 KB, vendor JS 176 KB | `ls` on the built `public/css`, `public/js` |
| `team-showcase` supports user_groups + per-group sorting | `kit/modules/blox/blox/team-showcase/README.md` |
| `content-collection` filters by author, renders citation view | `kit/modules/blox/blox/content-collection/README.md` |
| No tag-cloud block in Tailwind | `kit/modules/blox/blox/` directory listing (32 blocks) |
| Modules still resolve post-archival | Go proxy `@latest` / `@v/list` |
