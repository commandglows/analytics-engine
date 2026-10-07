"""Authenticated, review-only client for the shared analytics host API."""
import argparse
import json
import os
import re
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

MAX_RESPONSE = 1024 * 1024
PERIODS = ("7d", "30d", "90d", "6m")


class AnalyticsError(ValueError):
    pass


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def scope_id(value):
    if not re.fullmatch(r"[a-zA-Z0-9_.:-]{1,128}", value):
        raise AnalyticsError("Invalid project, opportunity or snapshot ID.")
    return value


def api_base(value):
    parsed = urlsplit(value)
    try:
        parsed.port
    except ValueError as error:
        raise AnalyticsError("Invalid API URL.") from error
    if (parsed.scheme != "https" or not parsed.hostname or parsed.username
            or parsed.password or parsed.query or parsed.fragment
            or parsed.path not in ("", "/")):
        raise AnalyticsError("API URL must be an HTTPS origin without credentials or path.")
    return value.rstrip("/")


def request_json(base, token, path, payload=None, opener=None):
    if not token or any(character.isspace() for character in token):
        raise AnalyticsError("Set SHIPGLOWS_ANALYTICS_TOKEN in the local secret environment.")
    headers = {"Accept": "application/json", "Authorization": f"Bearer {token}"}
    body = None
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
    request = Request(api_base(base) + path, data=body, headers=headers)
    transport = opener or build_opener(NoRedirect()).open
    try:
        with transport(request, timeout=30) as response:
            raw = response.read(MAX_RESPONSE + 1)
    except HTTPError as error:
        status = error.code
        error.close()
        reasons = {401: "Authentication required or expired.", 403: "Project access denied.",
                   404: "Project or opportunity unavailable.",
                   409: "Snapshot changed or action blocked. Refresh opportunities."}
        raise AnalyticsError(reasons.get(status, f"Analytics API failed (HTTP {status}).")) from None
    except (URLError, OSError, ValueError):
        raise AnalyticsError("Analytics API connection failed.") from None
    if len(raw) > MAX_RESPONSE:
        raise AnalyticsError("Analytics response exceeds the size limit.")
    try:
        result = json.loads(raw, parse_constant=lambda _: (_ for _ in ()).throw(ValueError()))
    except (ValueError, UnicodeError):
        raise AnalyticsError("Analytics API returned invalid JSON.") from None
    if not isinstance(result, dict):
        raise AnalyticsError("Analytics API returned an invalid object.")
    return result


def execute(args, env, opener=None):
    project = scope_id(args.project)
    root = f"/api/projects/{project}/content-intelligence/opportunities"
    is_brief = args.command == "brief"
    path = (root + "/" + scope_id(args.opportunity) + "/brief" if is_brief
            else root + "?" + urlencode({"period": args.period}))
    payload = ({"period": args.period, "snapshotId": scope_id(args.snapshot)}
               if is_brief else None)
    result = request_json(env.get("SHIPGLOWS_ANALYTICS_API_URL", "https://api.contentglows.com"),
                          env.get("SHIPGLOWS_ANALYTICS_TOKEN", ""), path, payload, opener)
    schema = "shipglows.analytics.brief.v1" if is_brief else "shipglows.analytics.v1"
    if (result.get("schemaVersion") != schema or result.get("projectId") != project
            or result.get("period") != args.period):
        raise AnalyticsError("Response schema or project/period scope does not match the request.")
    if is_brief and (result.get("snapshotId") != args.snapshot
                     or not isinstance(result.get("opportunity"), dict)
                     or result["opportunity"].get("id") != args.opportunity
                     or result.get("intendedAction") != "prepare_review_only"):
        raise AnalyticsError("Brief does not match the requested review-only action.")
    return result


def parser():
    root = argparse.ArgumentParser(prog="shipglows-analytics", description=__doc__)
    commands = root.add_subparsers(dest="command", required=True)
    for command in ("opportunities", "brief"):
        child = commands.add_parser(command)
        child.add_argument("--project", required=True)
        child.add_argument("--period", choices=PERIODS, default="30d")
        if command == "brief":
            child.add_argument("--opportunity", required=True)
            child.add_argument("--snapshot", required=True,
                               help="Exact snapshot ID displayed by opportunities or the app")
    return root


def main(argv=None):
    args = parser().parse_args(argv)
    try:
        result = execute(args, os.environ)
    except AnalyticsError as error:
        print(f"shipglows-analytics: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False, indent=2, allow_nan=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
