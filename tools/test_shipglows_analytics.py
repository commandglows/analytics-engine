import io
import json
import unittest
from urllib.error import HTTPError
from tools.shipglows_analytics import AnalyticsError, NoRedirect, execute, parser, request_json


class ClientTests(unittest.TestCase):
    env = {"SHIPGLOWS_ANALYTICS_TOKEN": "test-only"}

    def transport(self, result):
        def open_request(request, timeout):
            self.request = request
            self.assertEqual(timeout, 30)
            return io.BytesIO(json.dumps(result).encode())
        return open_request

    def test_opportunities_keep_scope_and_snapshot(self):
        result = {"schemaVersion": "shipglows.analytics.v1", "projectId": "p1",
                  "period": "30d", "snapshotId": "s1", "status": "stale"}
        args = parser().parse_args(["opportunities", "--project", "p1"])
        self.assertEqual(execute(args, self.env, self.transport(result)), result)
        self.assertEqual(self.request.get_method(), "GET")
        self.assertTrue(self.request.full_url.endswith("/p1/content-intelligence/opportunities?period=30d"))
        self.assertEqual(self.request.get_header("Authorization"), "Bearer test-only")

    def test_brief_posts_exact_snapshot_without_mutation_command(self):
        result = {"schemaVersion": "shipglows.analytics.brief.v1", "projectId": "p1",
                  "period": "7d", "snapshotId": "s1", "opportunity": {"id": "i1"},
                  "intendedAction": "prepare_review_only"}
        args = parser().parse_args(["brief", "--project", "p1", "--period", "7d",
                                   "--snapshot", "s1", "--opportunity", "i1"])
        self.assertEqual(execute(args, self.env, self.transport(result)), result)
        self.assertEqual(self.request.get_method(), "POST")
        self.assertEqual(json.loads(self.request.data), {"period": "7d", "snapshotId": "s1"})
        for key, value in [("snapshotId", "s2"), ("projectId", "p2"),
                           ("intendedAction", "publish"), ("period", "30d")]:
            with self.subTest(key=key), self.assertRaises(AnalyticsError):
                execute(args, self.env, self.transport({**result, key: value}))

    def test_missing_token_and_unsafe_destinations_never_connect(self):
        def forbidden(*args, **kwargs):
            self.fail("Unexpected network request")
        with self.assertRaises(AnalyticsError):
            request_json("https://example.com", "", "/api", opener=forbidden)
        for base in ["http://example.com", "https://u:p@example.com", "https://example.com/path",
                     "https://example.com?secret=x", "https://example.com:bad", "https://example.com/#x"]:
            with self.subTest(base=base), self.assertRaises(AnalyticsError):
                request_json(base, "test-only", "/api", opener=forbidden)

    def test_remote_errors_never_echo_body_or_credentials(self):
        for status in [401, 403, 404, 409, 500, 302]:
            def failing(*args, **kwargs):
                raise HTTPError("https://example.com", status, "SECRET", {}, io.BytesIO(b"SECRET"))
            with self.subTest(status=status), self.assertRaises(AnalyticsError) as caught:
                request_json("https://example.com", "test-only", "/api", opener=failing)
            self.assertNotIn("SECRET", str(caught.exception))
        self.assertIsNone(NoRedirect().redirect_request(None, None, 302, "", {}, "https://elsewhere.com"))

    def test_invalid_and_oversized_json_are_rejected(self):
        for raw in [b"[]", b"not-json", b'{"value":NaN}', b"x" * (1024 * 1024 + 1)]:
            with self.subTest(size=len(raw)), self.assertRaises(AnalyticsError):
                request_json("https://example.com", "test-only", "/api",
                             opener=lambda *a, **k: io.BytesIO(raw))

    def test_invalid_ids_cannot_change_route(self):
        args = parser().parse_args(["opportunities", "--project", "../other"])
        with self.assertRaises(AnalyticsError):
            execute(args, self.env, lambda *a, **k: self.fail("Unexpected network request"))


if __name__ == "__main__":
    unittest.main()
