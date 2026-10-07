import 'package:analytics_actions_flutter/analytics_actions_flutter.dart';
import 'package:flutter/material.dart';

void main() => runApp(const AnalyticsDemo());

/// Preview-only semantic spacing. Product hosts supply their governed tokens.
const previewInset = 24.0, previewGap = 12.0;

class AnalyticsDemo extends StatelessWidget {
  const AnalyticsDemo({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(useMaterial3: true), darkTheme: ThemeData.dark(useMaterial3: true),
    home: const DemoPage());
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Analytics — données fictives')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(previewInset), child:
      AnalyticsOpportunitiesView(
        snapshot: AnalyticsSnapshot(projectId: 'demo', period: '30d', status: 'ready',
          snapshotId: 'demo-sync', generatedAt: DateTime.now().toUtc(),
          limitations: const ['Données fictives. Aucune collecte réelle ni publication.'],
          opportunities: const [AnalyticsOpportunity(id: 'demo-opportunity',
            title: 'Cet article est visible, mais attire peu de clics',
            summary: 'Comparer le titre et la description aux intentions de recherche avant de préparer un test.',
            kind: 'low_ctr_high_impressions', actionLabel: 'Préparer un brief',
            canPrepare: true, url: 'https://example.com/article', contentId: 'demo-content',
            evidence: [AnalyticsEvidence(sourceLabel: 'Google Search Console · exemple',
              metric: 'impressions', value: 1200, unit: 'count', start: '2026-09-01',
              end: '2026-09-30', isPartial: false),
              AnalyticsEvidence(sourceLabel: 'Google Search Console · exemple',
              metric: 'ctr', value: 0.012, unit: 'ratio', start: '2026-09-01',
              end: '2026-09-30', isPartial: false)]),]),
        translate: (v) => switch (v) {
          'Where to focus' => 'Où concentrer ton énergie',
          'Prepare an improvement brief' => 'Préparer un brief d’amélioration',
          'See evidence' => 'Voir les preuves',
          'Measurement limits' => 'Limites des mesures',
          'Choose one improvement to prepare. Nothing is published.' => 'Choisis une amélioration à préparer. Rien ne sera publié.',
          'Hypothesis to review; no causal improvement is proven.' => 'Hypothèse à examiner ; aucun gain causal démontré.',
          _ => v,
        }, inset: previewInset, gap: previewGap,
        onPrepare: (_) async => showDialog<void>(context: context,
          builder: (ctx) => AlertDialog(title: const Text('Brief fictif'),
            content: const Text('Examiner le titre, proposer une version à revoir et définir la prochaine période de mesure. Rien n’est publié.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))])),
      )),
  );
}
