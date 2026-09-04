[![Netlify Status](https://api.netlify.com/api/v1/badges/cb559411-6b3a-4dc1-87e2-c7dc3f0c2514/deploy-status)](https://app.netlify.com/sites/trypanosomatics/deploys)

# [Trypanosomatics Lab Web Site](https://trypanosomatics.org/)

Static site built with [Hugo](https://gohugo.io/) and the (now legacy) [Academic
Kickstart](https://github.com/sourcethemes/academic-kickstart) theme. The theme
has since been renamed Wowchemy / Hugo Blox and this site is pinned to an old
version that does **not** upgrade cleanly. A migration is pending; until then,
keep using the exact Hugo version documented below.

---

## 1. Requirements

- **Hugo `v0.69.2` extended** — nothing newer. Later versions break the theme.
  Netlify is also pinned to `0.69.2` in `netlify.toml`.
- **Git** with submodule support (the theme is a git submodule).

### Install Hugo 0.69.2

Download the *extended* build for your platform from the Hugo releases page:

<https://github.com/gohugoio/hugo/releases/tag/v0.69.2>

Examples:

- Linux x86_64: `hugo_extended_0.69.2_Linux-64bit.tar.gz`
- macOS: `hugo_extended_0.69.2_macOS-64bit.tar.gz`
- Windows: `hugo_extended_0.69.2_Windows-64bit.zip`

```bash
# Linux example — unpack and put it on your PATH under a version-specific name
tar xzf hugo_extended_0.69.2_Linux-64bit.tar.gz hugo
sudo install hugo /usr/local/bin/hugo692
hugo692 version
# Hugo Static Site Generator v0.69.2-... /extended ...
```

Naming the binary `hugo692` keeps it from colliding with any modern `hugo` you
may have installed. All commands below use `hugo692`; use plain `hugo` only if
that is the pinned 0.69.2 build.

---

## 2. Clone and build

```bash
git clone --recurse-submodules https://github.com/trypanosomatics/academic-kickstart.git
cd academic-kickstart
```

If you already cloned without `--recurse-submodules`, fetch the theme now:

```bash
git submodule update --init --recursive
```

> The `themes/academic/` directory **must** be populated. An empty theme folder
> is the usual cause of build errors like
> `failed to extract shortcode: template for shortcode "alert" not found`.

Build the static site into `public/`:

```bash
hugo692
```

Run a live-reloading dev server at <http://localhost:1313/>:

```bash
hugo692 server
# or: ./view.sh   (runs `hugo --i18n-warnings server`; edit it to call hugo692)
```

---

## 3. Repository layout

| Path                | Purpose                                                              |
|---------------------|--------------------------------------------------------------------- |
| `config/_default/`  | Site configuration (`config.toml`, `params.toml`, `menus.toml`, `languages.toml`) |
| `content/home/`     | Home page widgets (about, people, posts, projects, publications, contact, …) |
| `content/post/`     | Blog posts / announcements                                           |
| `content/authors/`  | Lab members (People widget)                                          |
| `content/project/`  | Research projects                                                    |
| `content/publication/` | Publications                                                      |
| `content/talk/`     | Talks / events                                                       |
| `static/`           | Files served as-is (images, PDFs, `files/`)                          |
| `assets/`, `layouts/` | Local overrides of theme assets and templates                      |
| `themes/academic/`  | Theme — **git submodule**, do not edit                               |
| `public/`           | Generated output (git-ignored)                                       |

Theme docs (still useful for front-matter reference):
<https://wowchemy.com/docs/> and the archived
<https://sourcethemes.com/academic/docs/>.

---

## 4. Editing existing content

1. Find the Markdown file under `content/` (e.g. a post at
   `content/post/<slug>/index.md`, a person at
   `content/authors/<username>/_index.md`).
2. Edit the front matter (the `---` YAML or `+++` TOML block at the top) and/or
   the body text below it.
3. Preview with `hugo692 server` and check the page.
4. Commit and push to `master`. Netlify rebuilds and deploys automatically.

Common edits:

- **Add someone to a People group:** edit `user_groups` in their
  `content/authors/<username>/_index.md`. Valid groups (defined in
  `content/home/people.md`): `Investigators`, `Postdocs`, `Grad Students`,
  `Administration`, `Alumni`, `Past Lab Members`.
- **Site menus / navbar:** `config/_default/menus.toml`.
- **Home page sections:** the files in `content/home/` (set `active = false` to
  hide a widget).

---

## 5. Adding new content

### New post

```bash
hugo692 new --kind post post/my-post-slug
```

This creates `content/post/my-post-slug/index.md`. Then:

- Set `title`, `summary`, `authors` (list of usernames from `content/authors/`),
  `tags`, `date`, and `featured: true/false`.
- Keep `draft: false` to publish.
- Optional: drop a `featured.png` (or `.jpg`) into the post folder for the
  header/preview image.

### New author / lab member

1. Create the folder and profile file:
   `content/authors/<username>/_index.md`
   (copy an existing one such as `content/authors/mercedes/_index.md` as a
   template).
2. In the front matter set at least: `name`, `authors = ["<username>"]`,
   `<username> = [""]`, `role`, `organizations`, `user_groups`, `email`,
   `interests`, and the social/`[[social]]` links.
3. Add a square `avatar.jpg` in the same folder for the profile photo.
4. Reference the `<username>` in the `authors` list of any post/publication they
   belong to.

### New project / publication / talk

Use the matching archetype:

```bash
hugo692 new --kind project     project/my-project
hugo692 new --kind publication publication/my-publication
hugo692 new --kind talk        talk/my-talk
```

Fill in the front matter and add a `featured` image in the page folder if
wanted. Publications can also be imported from BibTeX with
[academic-admin](https://github.com/sourcethemes/academic-admin)
(`academic import --bibtex refs.bib`).

---

## 6. Deployment

Push to `master` on `github.com/trypanosomatics/academic-kickstart`. Netlify
builds with the settings in `netlify.toml` (`hugo`, `HUGO_VERSION = 0.69.2`,
publish dir `public/`) and deploys to <https://trypanosomatics.org/>.

Always confirm `hugo692` builds locally with no errors before pushing.

---

## 7. Notes / gotchas

- **Do not upgrade Hugo or the theme.** The theme submodule is intentionally
  pinned; `update_academic.sh` exists but running it will break the build.
- The build takes ~40 s (lots of image processing). Processed images are cached
  in `resources/` (git-ignored).
- Local template/asset overrides live in `layouts/` and `assets/`; the theme
  itself in `themes/academic/` should never be modified directly.

## License

Site content © the Trypanosomatics Lab. The Academic theme is © 2017–present
[George Cushen](https://georgecushen.com), released under the
[MIT](LICENSE.md) license.
