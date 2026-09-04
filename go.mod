module github.com/trypanosomatics/academic-kickstart

go 1.19

// Exact versions, deliberately. `hugo mod get ./...` will drift these to
// whatever is newest, which has already pulled in surprises once; upgrade by
// editing this file and rebuilding, then re-check layouts/OVERRIDES.md.
require (
	github.com/HugoBlox/kit/modules/analytics v0.3.1 // indirect
	github.com/HugoBlox/kit/modules/blox v0.0.0-20260527025321-61f41d3667f1
	github.com/HugoBlox/kit/modules/integrations/netlify v1.3.0
)
