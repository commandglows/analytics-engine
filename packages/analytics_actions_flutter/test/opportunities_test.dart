import 'dart:convert';
import 'package:analytics_actions_flutter/analytics_actions_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> fixture() => {
  'schemaVersion': 'shipglows.analytics.brief.v1',
  'projectId': 'project-1',
  'period': '30d',
  'snapshotId': 'sync-1',
  'generatedAt': DateTime.now().toUtc().toIso8601String(),
  'intendedAction': 'prepare_review_only',
  'opportunity': {
    'id': 'insight-1',
    'kind': 'low_ctr_high_impressions',
    'title': 'Examiner le titre de cet article',
    'summary':
        'La page est visible mais reçoit peu de clics. Vérifier l’intention avant de modifier le titre.',
    'distributionUrl': 'https://example.com/article',
    'contentId': 'content-1',
    'confidence': 0.8,
    'actionLabel': 'Préparer un brief',
    'canPrepare': true,
    'blockedReason': null,
    'evidence': [
      {
        'source': 'search_console',
        'sourceLabel': 'Google Search Console',
        'nativeMetric': 'impressions',
        'value': 1200,
        'unit': 'count',
        'periodStart': '2026-09-01',
        'periodEnd': '2026-09-30',
        'isPartial': false,
      },
      {
        'source': 'search_console',
        'sourceLabel': 'Google Search Console',
        'nativeMetric': 'ctr',
        'value': 0.012,
        'unit': 'ratio',
        'periodStart': '2026-09-01',
        'periodEnd': '2026-09-30',
        'isPartial': false,
      },
    ],
  },
  'limitations': [
    'La confiance est une heuristique, pas une probabilité de succès.',
  ],
};

AnalyticsSnapshot snapshot(AnalyticsBrief brief, {String status = 'ready'}) =>
    AnalyticsSnapshot(
      projectId: brief.projectId,
      period: brief.period,
      status: status,
      generatedAt: brief.generatedAt,
      snapshotId: brief.snapshotId,
      opportunities: [brief.opportunity],
      limitations: brief.limitations,
    );

void main() {
  test('brief accepts aggregate evidence and isolates caller mutations', () {
    final input = fixture();
    final brief = AnalyticsBrief.parse(jsonEncode(input));
    (input['opportunity'] as Map)['title'] = 'Changed';
    expect(brief.opportunity.title, 'Examiner le titre de cet article');
    expect(brief.agentPrompt, contains('Do not publish'));
    expect(brief.opportunity.evidence.last.displayValue, '1.2 %');
  });

  test('rejects private fields, unsafe URL, partial and expired evidence', () {
    final variants = <void Function(Map<String, dynamic>)>[
      (v) => (v['opportunity'] as Map)['kind'] = 'organic_click_decline',
      (v) => v['visitorEvents'] = [],
      (v) => (v['opportunity'] as Map)['distributionUrl'] =
          'https://example.com/a?email=x',
      (v) =>
          (((v['opportunity'] as Map)['evidence'] as List).first
                  as Map)['isPartial'] =
              true,
      (v) =>
          (((v['opportunity'] as Map)['evidence'] as List).first
                  as Map)['value'] =
              'private text',
      (v) => v['generatedAt'] = DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 8))
          .toIso8601String(),
      (v) => (v['opportunity'] as Map)['canPrepare'] = false,
      (v) => v['intendedAction'] = 'publish',
    ];
    for (final mutate in variants) {
      final input = fixture();
      mutate(input);
      expect(() => AnalyticsBrief.fromJson(input), throwsFormatException);
    }
    expect(() => AnalyticsBrief.parse(' ' * 65537), throwsFormatException);
  });

  testWidgets(
    'review action is explicit, evidence expandable, stale disabled',
    (tester) async {
      final brief = AnalyticsBrief.fromJson(fixture());
      var calls = 0;
      Future<void> pump(String state) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnalyticsOpportunitiesView(
                snapshot: snapshot(brief, status: state),
                translate: (v) => v,
                inset: 16,
                gap: 8,
                onPrepare: (_) async {
                  calls++;
                },
              ),
            ),
          ),
        ),
      );
      await pump('ready');
      expect(calls, 0);
      await tester.tap(find.text('See evidence'));
      await tester.pumpAndSettle();
      expect(find.text('ctr: 1.2 %'), findsOneWidget);
      await tester.ensureVisible(find.text('Prepare an improvement brief'));
      await tester.tap(find.text('Prepare an improvement brief'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      await pump('stale');
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('narrow dark view handles scaled long content without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final brief = AnalyticsBrief.fromJson(fixture());
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: AnalyticsOpportunitiesView(
                snapshot: snapshot(brief),
                translate: (v) => v,
                inset: 16,
                gap: 8,
                onPrepare: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
