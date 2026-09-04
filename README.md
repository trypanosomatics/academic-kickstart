[![Netlify Status](https://api.netlify.com/api/v1/badges/cb559411-6b3a-4dc1-87e2-c7dc3f0c2514/deploy-status)](https://app.netlify.com/sites/trypanosomatics/deploys)

# [Trypanosomatics Lab Web Site](https://trypanosomatics.org/)

Static site built with [Hugo](https://gohugo.io/) and
[Hugo Blox Kit](https://github.com/HugoBlox/kit) (Tailwind).

> Migrated from Academic v4 / Wowchemy. Background in `ANALYSIS.md`, the plan
> and decision record in `MIGRATION.md`.
>
> **Restyling the site? Start with `STYLING.md`.** Local template overrides and
> the rules for upgrading them are in `OVERRIDES.md`.

---

## 1. Requirements

| Tool | Version | Why |
|---|---|---|
| **Hugo extended** | **0.165.0** (min 0.161.1) | `extended` is required — Tailwind and image processing |
| **Go** | 1.21+ | the theme is a Hugo Module, not a submodule |
| **Node** | ≥ 22 | Hugo runs the Tailwind CLI through Node |
| **pnpm** | 10+ | installs `@tailwindcss/cli`, `pagefind` |

Get the **`hugo_extended`** build — *not* `hugo_extended_withdeploy`, which only
adds a `hugo deploy` command for S3/GCS/Azure that this site never uses.

```bash
curl -LO https://github.com/gohugoio/hugo/releases/download/v0.165.0/hugo_extended_0.165.0_linux-amd64.tar.gz
tar xzf hugo_extended_0.165.0_linux-amd64.tar.gz hugo
sudo install hugo /usr/local/bin/hugo
hugo version   # must say +extended
```

## 2. Build

```bash
git clone https://github.com/trypanosomatics/academic-kickstart.git
cd academic-kickstart
pnpm install         # Tailwind CLI + Pagefind
pnpm dev             # live reload on http://localhost:1313/
pnpm build           # production build: hugo --minify, then the search index
```

No `git submodule` step — the theme resolves through `go.mod`.

### Search in development

Search is powered by [Pagefind](https://pagefind.app/), which indexes the
**built HTML** after Hugo runs. `hugo server` renders from memory and never
produces that index, so under plain `pnpm dev` the site requests
`/pagefind/pagefind.js`, gets a 404, and the search box reports
*"Failed to initialize Pagefind"*. **This is expected, and does not affect the
deployed site** — `netlify.toml` runs the indexer after every build.

To exercise search locally:

```bash
pnpm dev:search      # build, index into static/pagefind/, then serve
```

That index is a snapshot: re-run the command after editing content. It is
git-ignored and never deployed. `pnpm clean:search` removes it.

## 3. Layout

| Path | Purpose |
|---|---|
| `config/_default/` | `hugo.yaml`, `params.yaml`, `menus.yaml`, `module.yaml`, `languages.yaml` |
| `content/_index.md` | the landing page — an ordered list of blocks |
| `content/blog/` `events/` `publications/` `projects/` | content |
| `content/authors/` | **stubs only** — one per person, so their page exists |
| `data/authors/` | **the actual profiles** (`hugoblox/author/v1`) |
| `data/themes/tryps.yaml` | the lab colour palette, light and dark |
| `assets/media/authors/` | avatars, named `<slug>.<ext>` |
| `assets/media/` | images referenced by blocks |
| `static/` | served as-is; `static/_redirects` holds the Netlify redirects |
| `layouts/` | local overrides — **read `OVERRIDES.md` before touching** |
| `hugo-blox/blox/site/style.css` | site CSS overrides (see `STYLING.md`) |
| `hugo-blox/blox/` | blocks written for this site (currently `tag-cloud`) |
| `archive/` | not built; see below |

## 4. Common edits

**A person's profile** — `data/authors/<slug>.yaml`, avatar at
`assets/media/authors/<slug>.<ext>`. Their `content/authors/<slug>/_index.md` is
only a stub that makes the page exist; the content lives in the data file.

**Who appears in the People section, and in which group** — `user_groups` in
their data file. The groups and their order are set on the `team-showcase`
block in `content/_index.md`.

**The home page** — `content/_index.md`. Section order is list order. Each
section's `id:` must match its anchor in `config/_default/menus.yaml`.

**Colours** — `data/themes/tryps.yaml` (light and dark).

**A new publication** — a folder under `content/publications/` with an
`index.md`. Use `publication_types: ["article-journal"]` (CSL names, not the old
numbers) and put the DOI under `hugoblox.ids.doi` so the Altmetric and
Dimensions badges pick it up.

## 5. About `archive/`

`archive/home-widgets/` holds the **old Academic v4 page-builder widgets** as
they were just before the migration. They are history, not features: four of
them (`demo`, `skills`, `experience`, `accomplishments`) were already
`active = false` on the live site. They are kept only for reference and for the
git history attached to them. Nothing in `archive/` is built.

If you want that kind of section back, use the Hugo Blox equivalents rather than
the archived files — `resume-experience`, `resume-skills`, `resume-awards`.

Other Hugo Blox blocks available but not yet used here, worth a look:
`stats`, `testimonials`, `faq`, `gallery`, `steps`, `focus-areas`,
`tech-stack`, `cta-card`, `comparison-table`, `pricing`.

## 6. Deployment

Push to `master`. Netlify builds per `netlify.toml` and deploys to
<https://trypanosomatics.org/>.

`static/_redirects` maps the pre-migration URLs (`/post/`, `/talk/`,
`/publication/`, `/project/`) onto the current ones. **Do not delete it** —
those paths appear in published papers.

## License

Site content © the Trypanosomatics Lab. Hugo Blox is © George Cushen,
[MIT](LICENSE.md).
