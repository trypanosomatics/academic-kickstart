---
# Leave the title empty to use the site title from params.yaml
title: ''
date: 2026-09-04
type: landing

# Section order below replaces the `weight` ordering of the old
# content/home/*.md widgets. The `id` of each section must match the anchors
# in config/_default/menus.yaml.
sections:
  - block: hero
    id: hero
    content:
      title: The Trypanosomatics Laboratory
      text: Working on data integration to discover new drugs and diagnostics for
        human pathogens.
    design:
      # compact | default | tall | viewport | none.  The banner is a wide, short
      # image, so `compact` keeps the hero from towering over it.
      size: compact
      background:
        # The banner behind the hero text. Resolved from assets/media/.
        image:
          filename: bubbles-wide-tryp-binary.jpg
          size: cover
          position: center
        # Sibling of `image`, NOT nested inside it — parse_block_v3 reads
        # $bg.text_color_light. It puts the `dark` class on the section so the
        # heading and body text render light over this dark banner in both
        # colour modes.
        text_color_light: true

  - block: resume-biography
    id: about
    content:
      username: trypanosomatics
      text: ''
    design:
      avatar:
        size: medium
        shape: circle

  - block: logos
    id: slider
    content:
      title: Software, Tools, Resources
      logos:
        - name: TDR Targets 6
          image: tdrtargets-logo-v6-260x260.jpg
          url: https://tdrtargets.org
          description: 'Chemogenomics database: drug discovery for neglected diseases'
        - name: APRANK
          image: aprank-v1.png
          url: /publications/2021-ricci-aprank-frontiers/
          description: A tool for genome-wide antigenicity predictions
        - name: ChagasTope
          image: chagastope.png
          url: https://chagastope.org
          description: An Atlas of Chagas Disease Antigens and Epitopes

  - block: collection
    id: posts
    content:
      title: Recent Posts
      count: 5
      order: desc
      filters:
        folders: [blog]
    design:
      view: card

  - block: collection
    id: featured
    content:
      title: Featured Publications
      subtitle: Highlights from our digital library
      count: 0
      order: desc
      filters:
        folders: [publications]
        featured_only: true
    design:
      view: article-grid
      columns: 2

  - block: collection
    id: talks
    content:
      title: Recent & Upcoming Talks
      subtitle: Find us at these events and meetings
      count: 5
      order: desc
      filters:
        folders: [events]
    design:
      view: card

  - block: portfolio
    id: projects
    content:
      title: Projects
      filters:
        folders: [projects]
      buttons:
        - name: All
          tag: '*'
        - name: Genetic Diversity
          tag: genetic diversity
        - name: Immunomics
          tag: immunomics
        - name: Drug Discovery
          tag: chemogenomics
      default_button_index: 0
    design:
      columns: 3

  - block: collection
    id: publications
    content:
      title: Recent Publications by lab members
      subtitle: From pre-prints to final publications, it's all here
      count: 5
      order: desc
      filters:
        folders: [publications]
    design:
      view: citation

  - block: tag-cloud
    id: tags
    content:
      title: Popular Topics
      subtitle: Built from tags in projects and publications
      taxonomy: tags
      count: 30
    design:
      font_size_min: 0.8
      font_size_max: 2.0

  - block: team-showcase
    id: people
    content:
      title: This is Us
      subtitle: The people behind the tryps
      user_groups:
        - Investigators
        - Grad Students
        - Postdocs
        - Alumni
        - Past Lab Members
        - Collaborators
        - Visitors
        - Administration
      sort_by: weight
      sort_ascending: true
    design:
      show_social: true
      show_interests: true
      show_role: true

  - block: contact-info
    id: contact
    content:
      title: Contact
      email: info@trypanosomatics.org
      phone: '+54 11 4006-1500 exts 2110, 2120, 2107'
      address:
        street: 25 de Mayo 1401
        city: San Martín
        region: Buenos Aires
        postcode: B1650HMP
        country: Argentina
        country_code: AR
      office_hours:
        - 'Monday – Friday 9:00 to 19:00 ART'
      text: 'Edificio IIB (Biotecnología), 1st Floor'
      social:
        - icon: brands/twitter
          url: https://twitter.com/trypanosomatics
          label: Follow us
        - icon: brands/github
          url: https://github.com/trypanosomatics
          label: Our code
      show_form: false

  # ── Map ──────────────────────────────────────────────────────────────────
  # Two options. Exactly one should be active; swap the comments to compare.
  #
  # OPTION A (active): Hugo Blox `map` block — MapLibre GL + OpenFreeMap.
  # Open source, no API key, no Google tracking. Renders an address card
  # beside the map.
  - block: map
    id: map
    content:
      title: Find us
      location:
        lat: -34.579239
        lng: -58.525103
        address: |-
          Instituto de Investigaciones Biotecnológicas (IIB)
          25 de Mayo 1401, 1st Floor
          B1650HMP San Martín, Buenos Aires, Argentina
      zoom: 15
      cta:
        phone: '+54 11 4006-1500'
        email: info@trypanosomatics.org
        directions:
          text: Get directions
    design:
      height: 420
      interactive: true

  # OPTION B: Google Maps embed on the contact block instead. Requires an API
  # key, which must be rotated — the old one was committed in plaintext — and
  # restricted by HTTP referrer. To use this, delete the `map` block above and
  # add these two keys to the `contact-info` block's `content:` instead.
  #
  #     map_embed: 'https://www.google.com/maps/embed/v1/place?key=YOUR_KEY&q=-34.579239,-58.525103&zoom=15'
  #     map_url: 'https://www.google.com/maps/search/?api=1&query=-34.579239,-58.525103'
---
