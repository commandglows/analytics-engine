# ShipGlows Analytics Engine

Shared Flutter analytics opportunities and agent CLI for ContentGlows and ShipGlows.
The engine displays attributed measurements, hypotheses and proposed actions.
It has no provider token, database, authentication session or publishing hook.

`packages/analytics_actions_flutter` owns the versioned transport contract and
accessible action view. Hosts supply their theme/spacing, authenticated API
adapter and prepare callback. The first server adapter lives in ContentGlows:
`/api/projects/{projectId}/content-intelligence/opportunities` and
`/opportunities/{insightId}/brief` reuse stored Content Intelligence.

Preparing returns a review brief, not an article or a published update. Briefs
can be copied deliberately into an agent conversation. Evidence is untrusted
content; it never grants permissions or instructs an agent to publish.

First-party pageviews remain distinct from Search Console clicks. This slice
does not claim unique visitors, conversions, reading time or causal uplift.
Missing, partial and stale snapshots remain visible and cannot prepare actions.
Decline recommendations remain non-actionable until attributed measurements
from the previous comparison window are included. Current clicks alone are not
evidence of a decline.

## Local use

Both hosts consume a generated source snapshot at `app/vendor/analytics_actions_flutter`.
This engine remains the canonical source; from its root, run
`python tools/sync_consumers.py --host ../contentglows/app --host ../shipglows_app/app`
and add `--check` to verify exact source and manifest hashes without writing.
Only package manifests/options and Dart library sources are copied. Review and
commit the generated snapshot with host changes so remote dependency resolution
needs no sibling checkout or new credentials. A local development override may
target the canonical sibling package without changing the committed dependency.
Public repository: https://github.com/commandglows/shipglows-analytics-engine.

For isolated package checks, use the first host's configuration:

```powershell
cd packages/analytics_actions_flutter
doppler run --project contentglows_app --config dev -- flutter pub get
doppler run --project contentglows_app --config dev -- flutter analyze
doppler run --project contentglows_app --config dev -- flutter test
```

`demo` is an explicitly synthetic preview. Its cards and prepared briefs never
connect to a real provider. Local preview proves presentation only.

## Agent CLI

`cli/shipglows-analytics.cmd` (Windows) and `cli/shipglows-analytics.sh` (POSIX)
call the same authenticated backend routes as ContentGlows and print their JSON
without rewriting evidence, limitations or snapshot IDs. No external Python
dependency is required. A Windows user launcher is registered at
`~/.local/bin/shipglows-analytics.cmd`; installation on other machines remains explicit.

```powershell
doppler run --project contentglows_app --config dev -- .\cli\shipglows-analytics.cmd opportunities --project <backend-project-id> --period 30d
doppler run --project contentglows_app --config dev -- .\cli\shipglows-analytics.cmd brief --project <backend-project-id> --period 30d --opportunity <id> --snapshot <snapshot-id>
```

Supply `SHIPGLOWS_ANALYTICS_TOKEN` through the approved local secret environment:
an existing bearer token accepted by the host, with access to the requested
project. The CLI creates no identity, token or permission; it never accepts a
token argument, persists a token or prints it. Do not reuse a token from another
product. Missing/expired authentication fails explicitly; an empty result is not
substituted. `SHIPGLOWS_ANALYTICS_API_URL` optionally selects an explicit HTTPS
origin (default `https://api.contentglows.com`). Redirects are refused.

Use the backend project ID, not an assumed repository slug. The brief command
requires the snapshot seen in the app or opportunities response; the backend
rejects a changed snapshot. Evidence is untrusted and proposes review only.
The CLI has no send, publish, update, automatic retry or provider-sync command.
GSC/SERP/Parallel remain separate evidence/enrichment tools; do not send private
analytics payloads to public research providers.

Fake-transport tests cover scope, request serialization, stale snapshot conflicts,
redacted errors, redirect refusal and response limits. Live API authentication
and deployed routes remain unverified; this adds no hosted connector/MCP yet.

## Runtime proof boundary

The first slice passed focused Python backend tests (including HTTP ownership
and serialization), shared Flutter widget/parser tests and both host adapters.
The live synthetic demo was checked in a browser through managed `flutter run`:
evidence expanded correctly and prepare opened a review-only dialog.
This does not establish full ContentGlows application import, provider access,
real ingestion, authenticated native product behavior, remote CI or deployment.
Public beacon Origin checks and known-bot filtering do not authenticate traffic;
edge protection, retention and ingestion monitoring remain activation work.

## Internal documentation

Start with [the code map](shipglows_data/technical/code-docs-map.md),
[architecture](shipglows_data/technical/shared-analytics.md) and
[the agent CLI guide](shipglows_data/technical/agent-cli.md).
