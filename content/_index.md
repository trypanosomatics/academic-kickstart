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
      text: Using and generating data to guide discovery of new drugs and diagnostics.

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
---
