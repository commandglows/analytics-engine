---
artifact: code_docs_map
metadata_schema_version: "1.0"
artifact_version: "1.0.0"
project: shipglows-analytics-engine
created: "2026-10-06"
updated: "2026-10-06"
status: active
source_skill: sg-docs
scope: analytics-code-docs-map
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

# Code documentation map

| Source | Primary documentation | Invariant / validation |
| --- | --- | --- |
| `packages/analytics_actions_flutter/lib/src/contracts.dart` | `shared-analytics.md` | Versioned aggregate evidence and strict brief parser; Flutter package tests |
| `packages/analytics_actions_flutter/lib/src/opportunities_view.dart` | `shared-analytics.md` | Host theme and review callback; package widget tests including narrow layout/text scaling |
| `tools/sync_consumers.py` and its tests | `shared-analytics.md` | Exact generated source and SHA256 manifest; Python sync tests and `--check` |
| `tools/shipglows_analytics.py`, `cli/shipglows-analytics.*`, client tests | `agent-cli.md` | Authenticated scoped transport, exact snapshot, no redirects or publish; six fake-transport tests |
| `demo/` | `../../demo/README.md` and `shared-analytics.md` | Synthetic data only; Flutter demo test/analyze and local preview |

Read this map before changing a mapped source. Update the owning guide whenever
schema, auth, response bounds, source attribution or activation behavior changes.
Host backend contracts are implemented in ContentGlows, not in this repository.
