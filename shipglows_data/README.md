---
artifact: technical_docs_index
metadata_schema_version: "1.0"
artifact_version: "1.0.0"
project: analytics-engine
created: "2026-10-06"
updated: "2026-10-06"
status: active
source_skill: sg-docs
scope: analytics-docs-index
owner: Diane
confidence: high
risk_level: medium
security_impact: yes
docs_impact: yes
linked_systems: []
depends_on: []
supersedes: []
evidence:
  - "Current source and local verification records reviewed on 2026-10-06."
next_review: "2026-11-06"
next_step: "Validate deployed routes and authorized live access before activation claims."
---

# Analytics engine documentation

The canonical project corpus is this root `shipglows_data/`; packages and demo do
not own separate corpora. Start with [the code map](technical/code-docs-map.md),
then [architecture and contracts](technical/shared-analytics.md) or
[the agent CLI guide](technical/agent-cli.md).

The active cross-product work contract remains in ContentGlows:
`../contentglows/shipglows_data/workflow/specs/lab/SPEC-shared-actionable-site-analytics.md`.
Do not duplicate its activation tracker here.

## Preservation ledger

The original root AGENTS.md instructions were moved unchanged into AGENT.md;
AGENTS.md is now a relative compatibility symlink. README.md remains the quick
entrypoint. Existing API ownership, proof boundaries and CLI setup were preserved
and expanded into the linked technical documents; no existing content was deleted.
