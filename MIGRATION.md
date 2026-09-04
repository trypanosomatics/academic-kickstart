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

1. Fix the 7 malformed author lists.
2. Add `title` / `first_name` / `last_name` to the 20 author profiles (keep `name`).
3. Convert TOML front matter to YAML (53 files), section by section, one commit each.

**Gate:** `hugo692 --gc` builds clean; URL / author-link / page-count parity vs §4.

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
   `name:` from author profiles; port `image`/`links`/`social` shapes.
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

## 8. Open questions

Not blocking Phase 1. Needed during Phase 2.

1. **Dark mode** — real `tryps` dark palette, a stock dark theme, or off?
2. **Hero image** — supply one, or drop it? (broken since before this migration)
3. **Analytics** — GA4, a privacy-preserving alternative, or none? (`UA-1674362-6` is dead)
4. **Superuser** — `fernan` or `trypanosomatics`?
5. **Inactive widgets** — delete `demo`, `skills`, `experience`, `accomplishments`, or park them?
6. **Maps API key** — rotate; MapLibre/OpenFreeMap needs no key at all
7. **Repo name** — rename `academic-kickstart` to what?

---

## 9. Progress log

| Date | Phase | Status |
|---|---|---|
| 2026-09-04 | Baseline | ✅ 256 URLs / 262 author links / 359 pages captured |
| 2026-09-04 | Phase 1 | 🚧 in progress on `content/normalise-front-matter` |
