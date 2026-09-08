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
| 6 | Map | MapLibre/OpenFreeMap active; Google embed documented alongside. On the old API key, see §8.11. |
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
| 2026-09-04 | Phase 1 | ✅ complete — 4 commits on `content/normalise-front-matter`, all gates green |
| 2026-09-04 | Phase 2 | 🚧 substantially done in one sprint (32 commits). See breakdown below. |
| 2026-09-04 | Phase 4 | 🚧 palette + dark mode done; fonts and overall styling not. |
| 2026-09-06 | — | Work resumed on `migrate/hugoblox-kit`. Phase 1 branch left unmerged, to be deleted (fully contained in this branch, no unique commits). This log reconciled against git history. |
| 2026-09-07 | Phase 4 | 🚧 hero banner: shortened + darkened; documented in `CONFIGURATION.md`. Toolchain brought up on a second machine (Go 1.27, pnpm pinned to 10.14). `pnpm build` clean: 466 pages / 0 warnings / 256 sitemap URLs. See §9.3. |
| 2026-09-07 | Phase 4 | ✅ reported narrow-viewport hero regression investigated — **not a bug**, the screenshot was a pre-`c151769` build. No code change. Headless-browser verification recipe added as §8.12. See §9.4. |

### 9.1 State as of 2026-09-06 — branch `migrate/hugoblox-kit` (HEAD `12bd4eb`)

All work below is committed on this branch. Not merged to `master`; `master`
still deploys the pinned-0.69.2 v4 stack.

**Done — Phase 2**

- ✅ Teardown of the v4 stack (`714f32d`): submodule, `.gitmodules`,
  `update_academic.sh`, `page_author.html.patch`, `config/_default/*.toml`,
  `data/themes`, `data/fonts`, `assets/scss`, old `layouts/` all removed.
- ✅ Scaffold (`f08e805`): HugoBlox Kit template imported as one commit — `go.mod`,
  `package.json`, `pnpm-lock.yaml`, `config/_default/*.yaml`, `netlify.toml`,
  `.npmrc`, `.gitattributes`. No upstream git history.
- ✅ Section renames via `git mv` only (`bd15bd4`): `post→blog`, `talk→events`,
  `publication→publications`, `project→projects`; `authors/` unchanged.
- ✅ Author profiles moved to the Kit data model — `data/authors/*.yaml`
  (`f3f309b`, `7505b2a`).
- ✅ `@handle` prefix stripped throughout (`82d6e77`) — the §5.2 must-fix; 121
  occurrences / 49 files.
- ✅ All 32 publications migrated to the structured `publication:` map
  (`826c37a`, §8.9). Build warnings 79 → 0.
- ✅ `publication_types` numeric → CSL view names (`7d8e45a`).
- ✅ Landing page `content/home/*.md` → `content/_index.md` with 11 blocks and
  their anchor IDs (`5f9acc1`). Inactive v4 widgets parked in
  `archive/home-widgets/` (§8.5).
- ✅ `tag-cloud` block written from scratch — `hugo-blox/blox/all-access/tag-cloud/`
  (`5f9acc1`). Full widget→block mapping in §5.4.
- ✅ Redirects: `static/_redirects` created (`5f9acc1`). Re-verify against §6
  before cutover.
- ✅ Builds on Hugo 0.165.0 (`23c3773`): 466 pages, 0 errors; 256/256 baseline
  URLs resolve.
- ✅ Navbar anchor bug worked around without an override — `/#id` menu URLs
  (`8c3f76e`, §8.10).
- ✅ Research-metrics overrides written for single + citation views
  (`a23ee89`, `316ba5e`): `layouts/_partials/{functions/get_doi,
  components/research-metrics, hooks/head-end/research-metrics, views/citation}.html`.
  `doi` moved to `hugoblox.ids.doi` in all 32 files; DOIs normalised to bare form.
- ✅ Pagefind wired for local dev (`970d780`).
- ✅ Author-card short bio + navbar logo restored (`7505b2a`).
- ✅ Docs added: `CONFIGURATION.md` (every old `params.toml` key mapped),
  `STYLING.md`, `OVERRIDES.md`, `PULL-REQUESTS.md` (5 upstream bugs assessed).

**Done — Phase 4 (styling), partial**

- ✅ `tryps` palette + dark mode — `data/themes/tryps.yaml` (§8.1); dark-mode
  navbar kept green for logo legibility (`15d4bcb`).
- ✅ Two upstream Google Fonts bugs fixed; theme picker disabled (`d66b987`, §8.8).
- ✅ Type scale / title weight matched to the old site (`a270401`).
- ⬜ `tryps` font pack (Play / Open Sans / PT Mono) and overall visual polish —
  not done.

**Open questions** — 1–7 all resolved (§8). Note two later reversals:
analytics moved to the real GA4 id `G-WDE728FHFE` (`a23ee89`), superseding §8.3;
map switched to the Google Maps embed with MapLibre commented out (`12bd4eb`),
superseding §8.11's "MapLibre active".

**Remaining before the Phase 2 gate (§7) — see §5.5**

- ⬜ Research-metrics badges on **list** views (compact / card / featured), not
  just single + citation. §7 requires both.
- ⬜ Full §7 verification on a Netlify **deploy preview**: contact form →
  Netlify Forms, RSS validity, `sitemap.xml`, Pagefind on the deployed site,
  no `jsdelivr` / `unpkg` references.
- ⬜ External co-authors are no longer hyperlinked (Kit links only resolvable
  profiles) — decide keep vs. restore (§5.5.4).
- ⬜ Pin exact module versions — `hugo mod get ./...` drifted to
  `kit v4.8.0+incompatible` once (§5.5.6).
- ✅ `README.md` rewritten for the Hugo Blox stack (setup, build, layout,
  `archive/`). Netlify badge + `repository.url` still to update at repo rename
  (§8.7 step 6).
- 🚧 `team-showcase` — `sort_by: weight` / `sort_ascending: true` now set on the
  block (`content/_index.md`), but members still need distinct per-group weights;
  today they mostly share one value so order inside a group is still a tie-break
  (Phase 1 finding).

**Phase 3 (cutover) — not started**

Tag `academic-v4-final`; merge (**not** squash); delete `origin/main` and
`origin/migrate-wowchemy`; rewrite `README.md`; rename repo → `trypanosomatics-website`
and relink Netlify (§8.7).

### 9.2 Local toolchain note

This branch needs **Go** (for Hugo module resolution), Node ≥20, and pnpm.

- **Go** — Hugo 0.165 does **not** require a specific version. `go.mod` declares
  `go 1.19` and any modern Go works (verified with 1.27). `netlify.toml`'s
  `GO_VERSION = "1.21.5"` is only the build-image pin; Go is used here solely to
  fetch/resolve modules, not to compile anything that affects output, so the
  local Go version is not build-sensitive. Put `/usr/local/go/bin` on `PATH`.
- **pnpm — use the pinned 10.14.0, not a newer major.** `package.json` has
  `packageManager: "pnpm@10.14.0"`; enable Corepack (`corepack enable`) and let
  it honour that pin. A newer global pnpm (a v12 was tried) silently rewrites
  `packageManager`, prepends a self-pinning block to `pnpm-lock.yaml`, and
  creates a `pnpm-workspace.yaml` — a lockfile format change that would need its
  own deliberate commit and a deploy-preview test. If it happens:
  `git checkout -- package.json pnpm-lock.yaml && rm -f pnpm-workspace.yaml`,
  then `npx --yes pnpm@10.14.0 install`.
- **`@parcel/watcher` "Ignored build scripts" warning** on `pnpm install` is
  benign — a transitive native dep of the Tailwind CLI and Pagefind that ships
  prebuilt binaries; the skipped `node-gyp` step is a source-compile fallback
  that linux-x64 does not need. Install exits 0. Silence it if desired with
  `pnpm.ignoredBuiltDependencies: ["@parcel/watcher"]` in `package.json` (its
  own small commit).

### 9.3 Session 2026-09-07 — hero banner + second-machine toolchain

Commits from this session: `26a7cfb` CLAUDE.md + log reconcile · `c151769`
hero shorten + doc · `663bbdc` fernan profile · `0d30a43` hero darken.
**All pushed** — `origin/migrate/hugoblox-kit` is level with local `HEAD`.

- **`CLAUDE.md`** added at repo root — orientation for future sessions (two
  stacks, this branch is active, build/content/override pointers).
- **Hero banner** (`content/_index.md` hero block; full write-up in
  `CONFIGURATION.md` → "The hero banner — height and background image"):
  - Was ~590 px tall vs the old site's ~260 px strip. Cause: two padding stacks
    — the global section band (`--hb-spacing-section`, 6 rem from
    `style.spacing: spacious`) plus the hero's own `design.size` preset.
  - Now `no_padding: true` + `design.spacing.padding: ["2.5rem","0","2.5rem","0"]`
    (emits inline `padding:` on the `<section>`, overriding the global rule).
    `design.size: none` is a **no-op** in blox `v0.0.0-20260527025321` — its
    empty class string is falsy in the Preact component and falls through to
    `default`. Use `no_padding`.
  - Darkened with `design.background.image.filters.brightness` (→
    `filter: brightness(...)` on `.home-section-bg`). Committed at `0.7`; the
    value is a live tuning knob. Caveat: any `filter` on that layer cancels the
    `background-attachment: fixed` parallax — **measured and confirmed in
    §9.4** — use a `background.gradient` scrim instead if parallax must stay.
- **Build verified on the second machine**: `pnpm build` → 466 pages, 0
  warnings / 0 errors, Pagefind 52 pages; `sitemap.xml` 256 URLs (baseline
  parity); 0 `jsdelivr` / `unpkg` references.
- **Not done / unchanged**: everything in §9.1 "Remaining before the Phase 2
  gate" except the README and `team-showcase sort_by` items, which are updated
  there. The list-view research-metrics badges are still the first substantive
  task.
- **Clean at session end** — hero `brightness` settled at `0.7` and committed
  in `0d30a43`.

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
5. ~~**README** — still describes the pinned 0.69.2 workflow.~~ **Done** — the
   branch `README.md` is the Hugo Blox version. Only the Netlify badge and
   `repository.url` remain, at repo rename (§8.7 step 6).
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

---

## 8.11 The old Google Maps API key — no rotation needed

Earlier notes in this file said the committed key "must be rotated". That was
over-cautious, and worth correcting so nobody spends time on it.

**A Maps JavaScript API key is public by design.** It is embedded in client-side
JavaScript and served in the page to every visitor. It is an identifier for
billing and quota, not a secret. Its presence in this repo's git history added
nothing to an exposure the live site already created on every page load, so
rotating it would not have recovered anything.

What actually protects such a key is its restrictions, and the ones on this key
are correct:

- **HTTP referrers** — `https://trypanosomatics.org`, `https://www.trypanosomatics.org`
- **API restriction** — Maps JavaScript API only

That caps the blast radius: the key cannot be used against Geocoding, Places or
Directions, and casual reuse on another site is rejected. Referrer checks read a
browser-supplied header, so a determined caller can forge one — Google is
explicit that restrictions reduce impact rather than prevent misuse — but the
worst case is quota consumption on one API, not data access. A billing budget
with alerts closes that off.

**Recommended action: delete the key, don't rotate it.** The site now uses
MapLibre GL with OpenFreeMap, which needs no key at all, and no key appears
anywhere in this branch. An unused credential is best removed. Keep it only if
you may switch back to the Google Maps embed (Option B in `content/_index.md`),
and if you do keep it, add a billing budget alert.

## 8.12 Visual regression checks — driving a real browser from WSL

Phase 4 is styling work, and screenshots passed back and forth are a slow and
lossy way to verify it. There is no Linux browser in this WSL box and no
`node_modules` (the toolchain is Hugo + pnpm scripts only, see §9.2), but
**Windows Chrome is reachable through WSL interop** and can screenshot any
viewport size headlessly. Two gotchas make it work; both cost an hour to find.

### Recipe

```bash
CHROME="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

# Serve something. Either the dev server:
export PATH="$HOME/.local/share/fnm/aliases/default/bin:$PATH"   # see below
hugo server --disableFastRender --port 1314 &
# …or the production build, which is what actually ships:
pnpm build && (cd public && python3 -m http.server 8899 &)

# Screenshot. The output path must be a WINDOWS path — Chrome is a Windows
# process and cannot write to a WSL path it was given in POSIX form.
OUT=$(wslpath -w "$PWD")
"$CHROME" --headless=new --hide-scrollbars --window-size=951,480 \
  --screenshot="$OUT\\shot.png" --virtual-time-budget=6000 \
  http://localhost:1314/
```

- **`wslpath -w`** converts the scratch directory to `\\wsl.localhost\...`.
  Passing a POSIX path writes nothing and reports no error.
- **Windows→WSL localhost works** (Chrome reaches a server bound in WSL).
  **WSL→Windows does not** on this box, so `--remote-debugging-port` is
  unreachable from here — CDP scripting is out; stick to `--screenshot`.
- Add `--disable-gpu` to force software compositing. Rendering was identical
  with and without it, so GPU-vs-software is not a variable worth chasing here.

### Windows clamps the window to ~500 px wide

`--window-size=380,700` silently renders at ~500 px and crops the PNG to 380.
The result *looks* like a horizontal-overflow bug and is not one. To test true
mobile widths, put the site in a sized iframe and screenshot the host page:

```html
<!doctype html><meta charset=utf-8>
<style>html,body{margin:0}iframe{border:0;display:block;width:375px;height:760px}</style>
<iframe src="http://localhost:1314/"></iframe>
```

An iframe has its own viewport, so this also reproduces a **live viewport
resize without a reload** — shrink `iframe.style.width` from a `setTimeout` and
screenshot after. That is the only way to exercise resize-invalidation bugs
here, since CDP is unavailable.

### Measure, don't eyeball

Comparing screenshots by eye at different window widths is how earlier sessions
got the type scale wrong. Reduce a render to numbers instead:

- **Flat vs textured** — per-band `ImageStat.Stat(...).stddev` over a horizontal
  strip. A background image scores sd ≈ 25–60; a solid fill scores **0.0**.
  This is what proved the hero banner was not painting at all rather than
  painting darkly.
- **Layout fingerprint** — rows containing light text
  (`(pixels.min(axis=2) > 200).sum(axis=1) > 3`), grouped into runs. The run
  boundaries are a scroll- and scale-invariant signature of a layout, precise
  enough to identify *which commit* a screenshot came from (§9.4).
- **Scale** — if the text is proportionally smaller than your render at the same
  pixel width, the source viewport was **wider** and the image was downscaled,
  or browser zoom was below 100%. Ratio of body-line pitch gives the factor;
  divide the screenshot width by it to recover the real CSS viewport.

### `node` is not on PATH — `fnm env` fails when `/run/user/$UID` is missing

Any Hugo build (`pnpm build`, `pnpm dev`, plain `hugo`) dies with:

```
TAILWINDCSS: failed to transform "/css/_entry.css" … binary with name "node" not found in PATH
```

**Root cause (diagnosed 2026-09-08).** Node is managed by **fnm**, which stores
a per-shell symlink under `XDG_RUNTIME_DIR`. That variable is set to
`/run/user/1000`, but the directory is created by systemd-logind at login — and
WSL usually spawns the shell *outside* a PAM login session, so it is never
created. `fnm env` then fails:

```
error: Can't create the symlink for multishells at "/run/user/1000/fnm_multishells/…":
No such file or directory (os error 2)
```

`~/.bashrc` runs `eval "$(fnm env)"`, so a failed `fnm env` evaluates to nothing
and **node is silently absent from PATH**. Confirm with
`loginctl show-user "$USER" -p Linger` — `User ID 1000 is not logged in or
lingering` is the tell, and `ls /run/user/` will be empty.

This hits **interactive shells too**, not just non-login ones. An earlier note
here blamed non-interactive shells skipping `~/.bashrc`; that was wrong.

**Durable fix — run once, survives WSL restarts:**

```bash
sudo loginctl enable-linger "$USER"
```

That starts `user@1000.service` at boot, which creates `/run/user/1000`.

**Fallback, already applied to `~/.bashrc`** (untracked by yadm, so it does not
propagate to other machines — reapply it there): the fnm block now points
`XDG_RUNTIME_DIR` at `~/.cache/xdg-runtime` when `/run/user/$UID` is absent,
before calling `fnm env`.

**One-off unblock in any shell**, no root and no config change:

```bash
export PATH="$HOME/.local/share/fnm/aliases/default/bin:$PATH"
```

## 9.4 Session 2026-09-07 (second) — the narrow-viewport "regression" was stale HTML

**Report:** at a reduced window width the hero banner image was missing —
flat dark band where the old v4 site shows the image.

**Verdict: not a bug in this branch. No code change was made.** The screenshot
was of a page built **before `c151769`** ("hero: document and shrink the landing
hero banner"). Recorded here so nobody re-investigates it.

### What was tested

The banner rendered **correctly in every case**: widths 320 / 375 / 500 / 610 /
760 / 820 / 880 / 928 / 951 / 1000 / 1080 / 1400 px, heights 250–900 px, on both
`hugo server` and a `pnpm build` production build, with GPU and with software
compositing, and after a live viewport resize with no reload. Method in §8.12.

### How the screenshot was identified

Two measurements settled it:

1. The hero band was `#272935` at **stddev 0.0** — perfectly flat. The
   `.home-section-bg` layer painted nothing; it was not a too-dark image.
2. The text was proportionally smaller than a 761 px-wide render, so the real
   CSS viewport was ~951 px (browser zoom ≈ 80 %). Re-rendering at 951×480 and
   comparing light-text row runs:

   | | title rows | body line 1 | body line 2 |
   |---|---|---|---|
   | Screenshot | 217–319 | 349–361 | 378–386 |
   | Current `HEAD` | 95–196 | 225–239 | 257–264 |
   | Hero as of `26a7cfb` (pre-`c151769`) | **217–319** | **348–362** | **380–383** |

The title sits 122 px lower than current `HEAD` renders it — exactly the `6rem`
section band plus the hero's own `sm:py-20`, which is what `c151769` removed.
The stale document's baked-in processed-image URL no longer resolved, hence the
flat band.

**If it recurs on a freshly restarted `pnpm dev` with a hard reload
(Ctrl+Shift+R), it is a new bug** — the above no longer explains it.

### `design.background.image.parallax` — confirmed inert here

§9.3 asserted that a `filter` on `.home-section-bg` cancels the
`background-attachment: fixed` parallax. **Now measured, and true.** Blox
defaults `parallax` to `true`; with `filters.brightness` set, toggling it
changes nothing — a full-band pixel diff of parallax on vs off gave a max
per-channel delta of 10/255 at 951 px (build noise) and exactly **0** at
1400×500.

So `parallax: false` was tried and **reverted**: no measurable effect, and it
was not the cause of the report. It remains a reasonable hardening if the
`brightness` filter is ever dropped — `fixed` buys nothing on a ~300 px band and
is unreliable on iOS Safari (untested here). Two-line change if wanted.

### Open Phase 4 item found on the way

**At ≤375 px the navbar wraps to two rows** — logo + site title on the first,
the hamburger alone on the second, making the green band ~85 px tall. Functional
but untidy, and it differs from the v4 site, which centres the logo and keeps
one row. Reproduce with the iframe harness in §8.12.

### Also this session

The Google Maps embed key was verified live after **Maps Embed API** was added
to its API restrictions (it had been restricted to Maps *JavaScript* API, a
different product). Spoofed-`Referer` `curl`:
`https://trypanosomatics.org/` → **200**, no key error; `http://localhost:1313/`
→ **403**. Production will render; the map is blank under `pnpm dev` unless
`http://localhost:*` is added to the key's referrer list. Leaving it off is the
tighter setting. This supersedes §8.11's "delete the key" recommendation — the
key is in use again, with a billing alert in place.
