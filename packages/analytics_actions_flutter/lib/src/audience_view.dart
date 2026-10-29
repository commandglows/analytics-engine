import 'package:flutter/material.dart';
import 'audience_contracts.dart';
import 'opportunities_view.dart' show AnalyticsTranslate;

/// Read-only audience report. Hosts supply semantic spacing and their own
/// Material theme; every figure is an anonymous aggregate from the backend.
class AudienceReportView extends StatelessWidget {
  const AudienceReportView({
    super.key,
    required this.report,
    required this.translate,
    required this.inset,
    required this.gap,
    this.maxRows = 10,
  });
  final AudienceReport report;
  final AnalyticsTranslate translate;
  final double inset, gap;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final tr = translate;
    final theme = Theme.of(context);
    final overview = report.overview;
    final stateLabel = switch (report.status) {
      'empty' =>
        'No measured visit yet. Add the audience tracker to the site and verify its domain.',
      'insufficient' =>
        'Fewer visitors than the anonymity threshold: figures stay hidden.',
      _ => 'Anonymous aggregates; small groups are hidden and counts are rounded.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr('How your content is read'), style: theme.textTheme.titleLarge),
        SizedBox(height: gap),
        Text(tr(stateLabel)),
        if (report.isReady && overview != null) ...[
          SizedBox(height: gap),
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              _Stat(label: tr('Visitors'), value: _count(overview.visitors)),
              _Stat(label: tr('Returning visitors'), value: _count(overview.returningVisitors)),
              _Stat(label: tr('Visits'), value: _count(overview.visits)),
              _Stat(label: tr('Page views'), value: _count(overview.pageviews)),
              if (overview.pagesPerVisit != null)
                _Stat(label: tr('Pages per visit'), value: overview.pagesPerVisit!.toStringAsFixed(1)),
              if (overview.avgEngagedSeconds != null)
                _Stat(label: tr('Attention time'), value: _duration(overview.avgEngagedSeconds!)),
            ].map((stat) => _StatCard(inset: inset, child: stat)).toList(),
          ),
          _Section(
            title: tr('What gets read'),
            empty: tr('No page reaches the anonymity threshold yet.'),
            gap: gap,
            children: [
              for (final page in report.pages.take(maxRows))
                _Row(
                  title: page.path,
                  subtitle: [
                    '${_count(page.visitors)} ${tr('visitors')}',
                    if (page.avgEngagedSeconds != null) _duration(page.avgEngagedSeconds!),
                    if (page.reached75 != null) '${_percent(page.reached75!)} ${tr('read to 75 %')}',
                  ].join(' · '),
                  semantic: page.reached75,
                ),
            ],
          ),
          _Section(
            title: tr('Pages that bring readers back'),
            empty: tr('Not enough first visits to compare yet.'),
            gap: gap,
            children: [
              for (final item in report.returns.take(maxRows))
                _Row(
                  title: item.path,
                  subtitle:
                      '${_percent(item.returnRate)} ${tr('came back')} · ${_count(item.firstVisitVisitors)} ${tr('first visits')}',
                  semantic: item.returnRate,
                ),
            ],
          ),
          _Section(
            title: tr('Common paths'),
            empty: tr('No path is frequent enough to show.'),
            gap: gap,
            children: [
              for (final item in report.transitions.take(maxRows))
                _Row(
                  title: '${item.fromPath} → ${item.toPath}',
                  subtitle: '${_count(item.visitors)} ${tr('visitors')}',
                ),
            ],
          ),
          _Section(
            title: tr('Authors'),
            empty: tr('No author reaches the anonymity threshold yet.'),
            gap: gap,
            children: [for (final item in report.authors.take(maxRows)) _groupRow(item, tr)],
          ),
          if (report.categories.isNotEmpty)
            _Section(
              title: tr('Categories'),
              empty: '',
              gap: gap,
              children: [for (final item in report.categories.take(maxRows)) _groupRow(item, tr)],
            ),
          _Section(
            title: tr('Clicks'),
            empty: tr('No outbound link, download or tracked button yet.'),
            gap: gap,
            children: [
              for (final item in report.clicks.take(maxRows))
                _Row(
                  title: [item.label, item.target].whereType<String>().join(' · '),
                  subtitle: '${_count(item.visitors)} ${tr('visitors')}',
                ),
            ],
          ),
          if (report.campaigns.isNotEmpty)
            _Section(
              title: tr('Campaigns (visitors who consented)'),
              empty: '',
              gap: gap,
              children: [
                for (final item in report.campaigns.take(maxRows))
                  _Row(
                    title: [item.source, item.medium, item.campaign].whereType<String>().join(' / '),
                    subtitle: '${_count(item.visitors)} ${tr('visitors')}',
                  ),
              ],
            ),
        ],
        if (report.limitations.isNotEmpty) ...[
          SizedBox(height: gap),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(tr('Measurement limits')),
            children: [
              for (final value in report.limitations)
                ListTile(contentPadding: EdgeInsets.zero, title: Text(tr(value))),
            ],
          ),
        ],
      ],
    );
  }

  Widget _groupRow(AudienceGroup item, AnalyticsTranslate tr) => _Row(
    title: item.key,
    subtitle: [
      '${_count(item.visitors)} ${tr('visitors')}',
      '${_count(item.views)} ${tr('views')}',
      if (item.avgEngagedSeconds != null) _duration(item.avgEngagedSeconds!),
    ].join(' · '),
  );
}

/// Counts are already rounded to tens by the backend: shown as "≈ 120".
String _count(int value) => '≈ $value';

String _percent(double ratio) => '${(ratio * 100).round()} %';

String _duration(double seconds) {
  final total = seconds.round();
  if (total < 60) return '$total s';
  return '${total ~/ 60} min ${(total % 60).toString().padLeft(2, '0')} s';
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.inset, required this.child});
  final double inset;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Card(child: Padding(padding: EdgeInsets.all(inset), child: child));
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.empty,
    required this.gap,
    required this.children,
  });
  final String title, empty;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: gap * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(title, style: theme.textTheme.titleMedium)),
          if (children.isEmpty && empty.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: gap),
              child: Text(empty, style: theme.textTheme.bodySmall),
            ),
          ...children,
        ],
      ),
    );
  }
}

/// One aggregate row; [semantic] (0..1) adds a progress bar with its value
/// already spelled out in [subtitle], so color is never the only signal.
class _Row extends StatelessWidget {
  const _Row({required this.title, required this.subtitle, this.semantic});
  final String title, subtitle;
  final double? semantic;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title, maxLines: 2, overflow: TextOverflow.fade, softWrap: true),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(subtitle),
        if (semantic != null)
          ExcludeSemantics(child: LinearProgressIndicator(value: semantic)),
      ],
    ),
  );
}
