#!/usr/bin/env bash
# Scaffold a new lab member's data/authors/<slug>.yaml, pre-filled with the
# schema and reasonable placeholders. `hugo new` cannot do this itself -- it
# only targets content/, and errors outright on a data/ path -- see
# README.md sec 4 and MIGRATION.md sec 9.9.
#
# Usage:
#   scripts/new-author.sh "Jane Doe" [slug]
#
# slug defaults to the display name, lowercased, accents stripped, spaces
# and anything non-alphanumeric collapsed to a single hyphen.
# Example: new-author.sh "Jane Doe" jane

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 \"Full Display Name\" [slug]" >&2
  exit 1
fi

display_name="$1"

if [ $# -ge 2 ]; then
  slug="$2"
else
  slug=$(printf '%s' "$display_name" \
    | iconv -f utf8 -t ascii//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
fi

if [ -z "$slug" ]; then
  echo "Could not derive a slug from '$display_name' -- pass one explicitly." >&2
  exit 1
fi

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

data_file="data/authors/$slug.yaml"

if [ -e "$data_file" ]; then
  echo "Already exists, aborting: $data_file" >&2
  exit 1
fi

# Best-effort given/family split: last word is the family name, everything
# before it is given. Wrong for compound-family-name cases -- fix by hand.
family=$(printf '%s' "$display_name" | awk '{print $NF}')
given=$(printf '%s' "$display_name" | sed -E 's/ [^ ]+$//')
if [ "$given" = "$display_name" ]; then
  given="$display_name"
  family=""
fi

cat > "$data_file" <<YAML
schema: hugoblox/author/v1
slug: $slug
name:
  display: $display_name
  given: $given
  family: $family
# TODO: fill in -- e.g. "PhD Student", "Postdoctoral Researcher"
role: "TODO"
# One-line summary shown on the author cards at the foot of a page.
short_bio: ""
# \`bio\` below is the full biography, used on the author's own profile page.
# Supports Markdown (headings, lists, links, bold/italic, ...) -- rendered
# through markdownify. Written as a YAML literal block scalar (the \`|\`)
# so it reads and edits like an ordinary Markdown file, not one escaped
# line -- replace this placeholder text.
bio: |
  # About me

  Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod
  tempor incididunt ut labore et dolore magna aliqua.

  Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi
  ut aliquip ex ea commodo consequat.
affiliations:
- name: Universidad de San Martín
  url: http://www.unsam.edu.ar
# CONICET fellows/researchers, add:
# - name: Consejo Nacional de Investigaciones Científicas y Técnicas (CONICET)
#   url: https://www.conicet.gov.ar
links:
- icon: at-symbol
  url: "mailto:TODO@iib.unsam.edu.ar"
  label: E-mail
interests: []
education: []
# REQUIRED -- pick from the team-showcase block's user_groups in
# content/_index.md: Investigators, Postdocs, Grad Students, Alumni,
# Past Lab Members, Collaborators, Visitors, Administration.
user_groups: []
weight: 10
email: TODO@iib.unsam.edu.ar
YAML

cat <<MSG
Created:
  $data_file

Still needed by hand:
  - avatar at assets/media/authors/$slug.<ext> (any aspect ratio; team-showcase
    center-crops it -- see OVERRIDES.md "Avatar cropping on the People grid")
  - role, short_bio, email
  - bio (currently lorem ipsum placeholder text)
  - user_groups (empty right now -- the person won't appear on the People
    grid until this is set)
  - double-check the given/family name split above; it's just "last word is
    the family name"

Note: $slug will show on the People grid immediately, but /authors/$slug/
won't exist until something -- any post, talk, project or publication --
cites "$slug" in its authors: list.
MSG
