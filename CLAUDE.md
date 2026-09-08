# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

The [Trypanosomatics Lab](https://trypanosomatics.org/) website: a Hugo static
site deployed by Netlify. Netlify site name `trypanosomatics`, deploy badge in
`README.md`. Most of the history is lab members editing their own profiles —
12+ contributors, incremental commits — which is why the migration below is a
branch in this repo, not a fresh start.

## Two stacks live in this repo — know which branch you are on

| Branch | Stack | Build | State |
|---|---|---|---|
| `master` | Academic Kickstart v4 theme, **git submodule** | Hugo **pinned 0.69.2 extended**, `hugo692` | Currently deployed. Frozen — no new work. |
| `migrate/hugoblox-kit` | HugoBlox Kit `blox` (Tailwind), **Go module** | Hugo 0.165 + Go + Node + pnpm + Pagefind | **Active branch.** Phase 2 substantially done; see `MIGRATION.md` §9. |

Everything below — commands, config format, content model — describes
**`migrate/hugoblox-kit`**, which is what `master` becomes at cutover. For the
frozen v4 stack on `master`, see that branch's own `README.md`; the short
version is `git submodule update --init --recursive` then `hugo692`, and do not
upgrade Hugo or the theme.

`origin/main` and `origin/migrate-wowchemy` are dead ends — abandoned attempts,
polluted history. Do not build on them; they are deleted at cutover.
`content/normalise-front-matter` (Phase 1) is fully contained in
`migrate/hugoblox-kit` with no unique commits — ignore it; it will be deleted.

## Build & develop (migrate/hugoblox-kit)

`README.md` on this branch has the full setup. Essentials:

- **Toolchain:** Hugo extended 0.165 (min 0.161.1), any modern **Go** (module
  resolution only — `go.mod` says `go 1.19`; version is not build-sensitive;
  `netlify.toml`'s `GO_VERSION` is just the build-image pin), Node ≥22, pnpm 10+.
- No `git submodule` step — the theme resolves through `go.mod`. Pin exact
  module versions; `hugo mod get ./...` drifts them (it once pulled
  `kit v4.8.0+incompatible`).
- `pnpm install` then `pnpm dev` → live reload on http://localhost:1313/
- `pnpm build` → production build + Pagefind index
- **Search** needs built HTML, so it 404s under plain `pnpm dev` — expected, not
  a bug. Use `pnpm dev:search` to exercise it locally.
- **`binary with name "node" not found in PATH`** kills any Hugo build. On WSL,
  `fnm env` fails when systemd-logind has not created `/run/user/$UID`, leaving
  node off PATH even in interactive shells. Fix once with
  `sudo loginctl enable-linger "$USER"`; unblock a single shell with
  `export PATH="$HOME/.local/share/fnm/aliases/default/bin:$PATH"`. Full
  diagnosis in `MIGRATION.md` §8.12.
- **Verify styling by screenshot, not by eye.** Windows Chrome drives headlessly
  from WSL at any viewport size — recipe, the ~500 px window-width clamp and its
  iframe workaround, and how to reduce a render to numbers: `MIGRATION.md` §8.12.
  Before filing a visual regression, check the page is not stale (§9.4).

## The migration — `MIGRATION.md` is the runbook

Read it in full before migration work. `MIGRATION.md` §9 is the live status.
`ANALYSIS.md` = why HugoBlox Kit ("option D"). `PLAN.md` is superseded on the
target choice — only its §1 inventory, §4 method, §7 content-mapping tables
still apply. Companion docs on this branch:

- `CONFIGURATION.md` — every old `params.toml` key mapped to where it lives now
- `STYLING.md` — colours (`data/themes/tryps.yaml`), fonts, CSS hook, overrides
- `OVERRIDES.md` — every local template override + the rule for re-checking them
  on a module upgrade. **Read before touching `layouts/`.**
- `PULL-REQUESTS.md` — upstream HugoBlox bugs the overrides work around

History-protection rules (`MIGRATION.md` §2) — Git infers renames by content
similarity:

1. Never combine a file move with an edit. `git mv` in its own commit; rewrite
   front matter in the next. Verify with `git log --follow <new-path>`.
2. Merge, never squash, when landing this branch.
3. Never import the HugoBlox template's git history — scaffold files come in as
   one plain commit.
4. `git tag academic-v4-final` before the cutover merge.

Section renames (`/post/`→`/blog/`, `/talk/`→`/events/`, `/publication[s]/`,
`/project[s]/`) change public URLs cited in papers. `static/_redirects` must
carry a 301 for every moved URL — `MIGRATION.md` §6. `/authors/`, `/tags/`,
`/categories/` must NOT change; do not adopt the upstream `permalinks:` block.

Parity baseline (256 sitemap URLs / 262 author links / 359 pages, captured
2026-09-04) is the verification gate — `MIGRATION.md` §4 and §7. Regenerate the
`baseline-*.txt` artefacts into a durable location before running §7.

## Content model (this branch)

- **Lab members:** `data/authors/<slug>.yaml` (`hugoblox/author/v1`) is the real
  profile; `content/authors/<slug>/_index.md` is a stub so the page exists.
  Avatar at `assets/media/authors/<slug>.<ext>`. `user_groups` in the data file
  controls People-section grouping; group set and order live on the
  `team-showcase` block in `content/_index.md`.
  - `team-showcase` has no default sort yet — order within a group is an
    arbitrary tie-break. Set an explicit `sort_by` + distinct member weights
    before cutover (`MIGRATION.md` §9 Phase 1 finding).
- **Landing page:** `content/_index.md` — an ordered list of blocks; section
  order is list order. Each block's `id:` must match its anchor in
  `config/_default/menus.yaml`. Menu URLs are written `/#id` (leading slash) to
  dodge an upstream anchor bug — see `MIGRATION.md` §8.10.
- **Publications:** folder under `content/publications/` with `index.md`. Use
  `publication_types: ["article-journal"]` (CSL names, not old numbers); DOI
  under `hugoblox.ids.doi` so the Altmetric/Dimensions badges resolve. Structured
  `publication:` map, not the old flat string (`MIGRATION.md` §8.9).
- **Config:** `config/_default/*.yaml`. Analytics uses the GA4 id
  `G-WDE728FHFE` (supersedes `MIGRATION.md` §8.3). Map uses the Google Maps
  embed, MapLibre commented (supersedes §8.11).
- **Site CSS:** `hugo-blox/blox/site/style.css`. Blocks written for this site
  (currently `tag-cloud`): `hugo-blox/blox/`.
- `archive/` is not built — old v4 widgets kept for reference only.

## Session / notes hygiene

- `claude.session` is git-ignored — do not commit Claude session transcripts or
  pointers into this repo (it is public).
- Update `MIGRATION.md` §9 when you complete a step; keep it reconciled with
  actual git state, not intentions.
