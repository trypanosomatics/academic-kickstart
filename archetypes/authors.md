---
# Profile data lives in data/authors/{{ .File.ContentBaseName }}.yaml
# This stub exists so the author's term page is generated even when no
# content references them.
title: "{{ replace .File.ContentBaseName "-" " " | title }}"
---
