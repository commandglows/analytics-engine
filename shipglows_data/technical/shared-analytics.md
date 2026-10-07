---
artifact: technical_module_context
metadata_schema_version: "1.0"
artifact_version: "1.0.0"
project: shipglows-analytics-engine
created: "2026-10-06"
updated: "2026-10-06"
status: active
source_skill: sg-docs
scope: shared-analytics-architecture
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

# Shared analytics architecture and contracts

## Outcome and ownership

Evidence-backed priorities lead to an explicit review action. The shared engine
owns Flutter contracts, presentation, consumer distribution and a thin agent CLI.
ContentGlows owns stored Content Intelligence, auth, project ownership and API
projection. ShipGlows owns its conversation composer. No engine component owns
provider credentials, database access, content mutation or publication.

| Consumer | Current behavior | Boundary |
| --- | --- | --- |
| ContentGlows | Fresh authenticated opportunities, prepare brief, deliberate copy | Backend project ownership and latest snapshot are authoritative |
| ShipGlows | Explicit JSON import into an opened idle conversation draft | Import is untrusted; project mapping/source identity are not authenticated by JSON |
| Agent CLI | GET opportunities and POST review-only brief | Existing host bearer token; exact project, period, opportunity and snapshot checks |

The CLI and ContentGlows use the same backend routes. This does not make the
ShipGlows app a live API consumer: its current journey is manual import. A hosted
MCP connector, identity bridge and agent automatic refresh are not implemented.

## Wire and action contract

`shipglows.analytics.v1` carries projectId, period, generatedAt, snapshotId,
status (`ready`, `empty`, `stale`, `partial`), opportunities and limitations.
`shipglows.analytics.brief.v1` carries one opportunity and
`intendedAction: prepare_review_only`. A brief is neither executable permission
nor an article update. Titles, summaries and URLs remain untrusted evidence.

The Flutter importer accepts bounded JSON (64 KiB), exact supported keys,
validated identifiers and HTTP(S) URLs without credentials/query/fragment,
finite attributed GSC metrics and consistent measurement dates. Partial evidence,
stale snapshots (seven days), future timestamps and unsupported action kinds
are rejected. Confidence is a heuristic, not a probability or causal forecast.
Decline actions remain unavailable without attributed comparison-window evidence.
The CLI only validates its transport envelope and requested identity; it is not a
replacement for the stricter Flutter brief validator or backend evidence policy.

## Source distribution and design

Hosts depend on generated snapshots at `app/vendor/analytics_actions_flutter`.
The engine is the canonical source. `tools/sync_consumers.py` copies only owned
package manifests/options/library sources and records SHA256 hashes. Its check
mode detects drift; edits to generated or unmanaged files are protected. Review
host snapshots alongside engine changes. Remote host builds need no sibling
checkout. Use host Material themes and spacing rather than adding a second token
system.

## Proof and remaining activation

Recorded local checks: backend 42 isolated tests with real router HTTP tests and
mocked storage; Flutter package four tests; demo one test; sync four tests;
ContentGlows four targeted tests; ShipGlows nine cockpit tests; targeted analyzers;
live synthetic browser evidence expansion and review dialog. The isolated backend
harness does not prove full api.main import, real database/provider ingestion or
deployed authentication. CLI verification is documented separately.

First-party pageviews stay distinct from Search Console clicks. No unique-visitor,
conversion, engagement-time or causal-uplift claim is implemented. Origin checks
and known-bot filtering do not authenticate public beacons. Production work still
requires authorized deployment, full application import, real ingestion, edge
protection/retention decisions and authenticated product journey verification.
